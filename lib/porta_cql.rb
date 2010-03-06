require 'strscan'

class QueryError < RuntimeError; end
class QuerySyntaxError < QueryError; end

class Cql
  def initialize(line)
    @query = split_clause_text(line).collect{|txt| Clause.new(txt)}

    from_day, @query = extract_with_index(@query, /from/io)
    @from = comp_date(from_day)
    until_day, @query = extract_with_index(@query, /until/io)
    @until = comp_date(until_day)
    sort_by, @query = extract_with_index(@query, /sortBy/io)
    @sort_by = sort_by ? sort_by.terms.first : ''
  end

  attr_reader :query, :from, :until, :sort_by, :and_or
  
  def ==(other)
    instance_variables.all? do |val|
      instance_variable_get(val) == other.instance_variable_get(val)
    end
  end

  def to_sunspot
    (@query.collect{|c| c.to_sunspot} + date_range(@from, @until)).join(" #{and_or} ")
  end

  def split_clause_text(line)
    clause_texts = []
    last_and_or = nil
    
    text = ''
    quoted = ''
    line.split.each do |token|
      case token
      when /\A\\".+/
        quoted << token
      when /.+\\"\Z/
        quoted << token
        text << ' ' + quoted
        quoted = ''
      when /\A(AND|OR)\Z/i
        and_or = $1.upcase
        raise QuerySyntaxError if last_and_or and last_and_or != and_or
        last_and_or = and_or
        clause_texts << text
        text = ''
      else
        if quoted.empty?
          text << ' ' unless text.empty?
          text << token
        else
          quoted << ' ' + quoted
        end
      end
    end
    @and_or = last_and_or
    clause_texts << text
    clause_texts.collect{|txt| txt.gsub(/(\A\(|\)\Z)/, '')}
  end

  private
  def extract_with_index(arr, reg)
    element, rest = arr.partition{|c| reg =~ c.index }
    [element.last, rest]
  end
  
  def date_range(from_date, until_date)
    unless from_date == '*' and until_date == '*'
      ["date_of_publication_d:[#{from_date} TO #{until_date}]"]
    else
      []
    end
  end
  
  def comp_date(date)
    if date
      text = date.terms[0]
      case text
      when /\A\d{4}-\d{2}-\d{2}\Z/
        (text + 'T00:00:00Z')
      when /\A\d{4}-\d{2}\Z/
        (text + '-01T00:00:00Z')
      when /\A\d{4}\Z/
        (text + '-01-01T00:00:00Z')
      else
        raise QuerySyntaxError, "#{text}"
      end
    else
      '*'
    end
  end
end

class ScannerError < QuerySyntaxError; end
class AdapterError < QuerySyntaxError; end

class Clause
  INDEX = /(dpid|dpgroupid|title|creator|publisher|ndc|description|subject|isbn|issn|jpno|from|until|anywhere|porta_type|digitalize_type|webget_type|payment_type|ndl_agent_type|ndlc|itemno)/io
  SORT_BY = /sortBy/io
  RELATION = /(=|exact|\^|any|all)/io

  MATCH_ALL = %w[title creator publisher]
  MATCH_EXACT = %w[dpid dpgroupid isbn issn jpno porta_type digitalize_type webget_type payment_type ndl_agent_type itemno]
  MATCH_PART = %w[description subject anywhere]
  MATCH_AHEAD = %w[ndc ndlc]
  MATCH_DATE = %w[from until]
  LOGIC_ALL = %w[title creator publisher description subject anywhere],
  LOGIC_ANY = %w[dpid ndl_agent_type],
  LOGIC_EQUAL = %w[dpgroupid ndc isbn issn jpno from until porta_type digitalize_type webget_type payment_type ndlc itemno],
  MULTIPLE = %w[dpid title creator publisher description subject anywhere ndl_agent_type]
  
  TYPE = {'text' => %w[title creator publisher subject], 'sm' => %w[isbn issn]}

  def initialize(text)
    unless text.empty?
      @index, @relation, @terms = scan(text)
      porta_adapter
      @field = @index
      @type = get_type(@field)
    else
      @index = ''
    end
  end

  attr_reader :index, :relation, :terms, :type

  def ==(other)
    instance_variables.all? do |val|
      instance_variable_get(val) == other.instance_variable_get(val)
    end
  end

  def scan(text)
    ss = StringScanner.new(text)
    index = ''
    relation = ''
    terms = []

    if ss.scan(INDEX) or ss.scan(SORT_BY)
      index = ss[0]
    else
      raise ScannerError, "index or the sortBy is requested in '#{text}'"
    end
    ss.scan(/\s+/)
    if ss.scan(RELATION)
      relation = ss[0].upcase
    else
      raise ScannerError, "relation is requested in '#{text}'"
    end
    ss.scan(/\s+/)
    if ss.scan(/.+/)
      terms = ss[0].gsub(/(\A\"|\"\Z)/, '').split
    else
      raise ScannerError, "search term(s) is requested in '#{text}'"
    end

    [index, relation, terms]
  end

  def porta_adapter
    logic_adapter
    multiple_adapter
  end

  def logic_adapter
    case
    when LOGIC_ALL.include?(@index)
      raise AdapterError unless %w[ALL ANY = EXACT ^].include?(@relation)
    when LOGIC_ANY.include?(@index)
      raise AdapterError unless %w[ANY =].include?(@relation)
    when LOGIC_EQUAL.include?(@index)
      raise AdapterError unless %w[=].include?(@relation)
    end
  end

  def multiple_adapter
    unless MULTIPLE.include?(@index)
      raise AdapterError if @terms.size > 1
    end
  end
      
  def to_sunspot
    case
    when MATCH_ALL.include?(@index)
      to_sunspot_match_all
    when MATCH_EXACT.include?(@index)
      to_sunspot_match_exact
    when MATCH_PART.include?(@index)
      to_sunspot_match_part
    when MATCH_AHEAD.include?(@index)
      to_sunspot_match_ahead
    when @index.empty?
      ''
    end
  end

  def to_sunspot_match_all
    term = @terms.join(' ')
    case @relation
    when /\A=\Z/
      "%s_%s:%s" % [@field, @type, ahead_to_sunspot(term)]
    when /\AEXACT\Z/
      "%s_%s:%s" % [@field, @type, exact_to_sunspot(term)]
    when /\AANY\Z/
      "%s_%s:%s" % [@field, @type, multiple_to_sunspot(@terms, :any)]
    when /\AALL\Z/
      "%s_%s:%s" % [@field, @type, multiple_to_sunspot(@terms, :all)]
    else
      raise QuerySyntaxError
    end
  end

  def to_sunspot_match_exact
    case @relation
    when /\A=\Z/
      term = @terms.join(' ')
      "%s_%s:%s" % [@field, @type, exact_to_sunspot(term)]
    when /\AANY\Z/
      "%s_%s:%s" % [@field, @type, multiple_to_sunspot(@terms.map{|t| exact_to_sunspot(t)}, :any)]
    else
      raise QuerySyntaxError
    end
  end

  def to_sunspot_match_part
    case @relation
    when /\A=\Z/
      term = @terms.join(' ')
      "%s_%s:%s" % [@field, @type, trim_ahead(term)]
    when /\AANY\Z/
      "%s_%s:%s" % [@field, @type, multiple_to_sunspot(@terms, :any)]
    when /\AALL\Z/
      "%s_%s:%s" % [@field, @type, multiple_to_sunspot(@terms, :all)]
    else
      raise QuerySyntaxError
    end
  end

  def to_sunspot_match_ahead
    "%s_%s:%s*" % [@field, @type, @terms.first]
  end

  private
  def get_type(index)
    type = ''
    TYPE.each do |tp, mbr|
      if mbr.include? index
        type = tp
        break
      end
    end
    type
  end

  def ahead_to_sunspot(term)
    /\A\^(.*)/ =~ term ? $1 + '*' : term
  end

  def exact_to_sunspot(term)
    '"' + term + '"'
  end
  
  def multiple_to_sunspot(terms, relation)
    boolean = relation == :any ? ' OR ' : ' AND '
    "(#{terms.map{|t| trim_ahead(t)}.join(boolean)})"
  end
  
  def trim_ahead(term)
    term.sub(/^\^+/,'')
  end
end

if $PROGRAM_NAME == __FILE__
  require 'porta_cql_test'
end