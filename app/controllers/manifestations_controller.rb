# -*- encoding: utf-8 -*-
class ManifestationsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!, :only => :edit
  before_filter :get_patron
  before_filter :get_manifestation, :only => :index
  before_filter :get_expression
  before_filter :get_series_statement, :only => [:index, :new, :edit]
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :get_libraries, :only => :index
  before_filter :get_version, :only => [:show]
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  after_filter :convert_charset, :only => :index
  #cache_sweeper :manifestation_sweeper, :only => [:create, :update, :destroy]
  include EnjuOai::OaiController

  # GET /manifestations
  # GET /manifestations.json
  def index
    @seconds = Benchmark.realtime do
      if params[:mode] == 'add'
        unless current_user.try(:has_role?, 'Librarian')
          access_denied; return
        end
      end
      @oai = check_oai_params(params)
      next if @oai[:need_not_to_search]
	    if user_signed_in?
	      @user = current_user unless @user
	    end

      if params[:format] == 'oai'
        from_and_until_times = set_from_and_until(Manifestation, params[:from], params[:until])
        from_time = @from_time = from_and_until_times[:from]
        until_time = @until_time = from_and_until_times[:until]
        # OAI-PMHのデフォルトの件数
        per_page = 200
        if params[:resumptionToken]
          if current_token = get_resumption_token(params[:resumptionToken])
            page = (current_token[:cursor].to_i + per_page).div(per_page) + 1
          else
            @oai[:errors] << 'badResumptionToken'
          end
        else
        end
        page ||= 1

        if params[:verb] == 'GetRecord' and params[:identifier]
          begin
            @manifestation = Manifestation.find_by_oai_identifier(params[:identifier])
          rescue ActiveRecord::RecordNotFound
            @oai[:errors] << "idDoesNotExist"
            render :template => 'manifestations/index.oai.builder'
            return
          end
          render :template => 'manifestations/show.oai.builder'
          return
        end
      end

      if params[:format] == 'csv'
        per_page = 65534
      end

      manifestations = {}
      @count = {}
      query = ""
      sort = {}

      page ||= params[:page] || 1
      per_page ||= Manifestation.per_page
			case
      when params[:format] == 'sru'
        if params[:operation] == 'searchRetrieve'
          sru = Sru.new(params)
          query = sru.cql.to_sunspot
          sort = sru.sort_by
        else
          render :template => 'manifestations/explain', :layout => false
          return
        end
      when params[:api] == 'openurl' 
        openurl = Openurl.new(params)
        @manifestations = openurl.search
        query = openurl.query_text
        sort = set_search_result_order(params[:sort_by], params[:order])
      else
        query = make_query(params[:query], params)
        sort = set_search_result_order(params[:sort_by], params[:order])
      end

      # 絞り込みを行わない状態のクエリ
      @query = query.dup
      query = query.gsub('　', ' ')

      search = Manifestation.search(:include => [:carrier_type, :required_role, :patrons, :expressions, :items])
      role = current_user.try(:role) || Role.default_role
      oai_search = true if params[:format] == 'oai'
      unless params[:mode] == 'add'
        manifestation = @manifestation if @manifestation
        patron = @patron if @patron
        expression = @expression if @expression
      end

      search.build do
        fulltext query unless query.blank?
        with(:original_manifestation_ids).equal_to manifestation.id if manifestation
        order_by sort[:sort_by], sort[:order] unless oai_search
        order_by :updated_at, :desc if oai_search
        with(:original_manifestation_ids).equal_to manifestation.id if manifestation
        with(:expression_ids).equal_to expression.id if expression
        with(:patron_ids).equal_to patron.id if patron
      end
      search = make_internal_query(search)
      all_result = search.execute!
      @count[:query_result] = all_result.total

      if session[:search_params]
        unless search.query.to_params == session[:search_params]
          clear_search_sessions
        end
      else
        clear_search_sessions
        session[:params] = params
        session[:search_params] == search.query.to_params
        session[:query] = @query
      end

      unless session[:manifestation_ids]
        manifestation_ids = search.build do
          paginate :page => 1, :per_page => configatron.max_number_of_results
        end.execute!.raw_results.collect(&:primary_key).map{|id| id.to_i}
        session[:manifestation_ids] = manifestation_ids
      end
        
      page ||= params[:page] || 1
      if params[:format] == 'sru'
        search.query.start_record(params[:startRecord] || 1, params[:maximumRecords] || 200)
      else
        search.build do
          facet :carrier_type
          facet :library
          facet :language
          facet :subject_ids
          paginate :page => page.to_i, :per_page => per_page || Manifestation.per_page
        end
      end
      search_result = search.execute
      if @count[:query_result] > configatron.max_number_of_results
        max_count = configatron.max_number_of_results
      else
        max_count = @count[:query_result]
      end
      @manifestations = WillPaginate::Collection.create(page, per_page, max_count) do |pager|
        pager.replace(search_result.results)
      end

      if params[:format].blank? or params[:format] == 'html'
        @carrier_type_facet = search_result.facet(:carrier_type).rows
        @language_facet = search_result.facet(:language).rows
        @library_facet = search_result.facet(:library).rows
      end

      @search_engines = Rails.cache.fetch('search_engine_all'){SearchEngine.all}

      save_search_history(query, @manifestations.offset, @count[:query_result], current_user)
      if params[:format] == 'oai'
        unless @manifestations.empty?
          set_resumption_token(params[:resumptionToken], @from_time || Manifestation.last.updated_at, @until_time || Manifestation.first.updated_at)
        else
          @oai[:errors] << 'noRecordsMatch'
        end
      end
    end

    store_location # before_filter ではファセット検索のURLを記憶してしまう

    respond_to do |format|
      format.html
      format.json { render :json => @manifestations }
      format.sru  { render :layout => false }
      format.rss  { render :layout => false }
      format.csv  { render :layout => false }
      format.rdf  { render :layout => false }
      format.atom
      format.oai {
        case params[:verb]
        when 'Identify'
          render :template => 'manifestations/identify'
        when 'ListMetadataFormats'
          render :template => 'manifestations/list_metadata_formats'
        when 'ListSets'
          @series_statements = SeriesStatement.all
          render :template => 'manifestations/list_sets'
        when 'ListIdentifiers'
          render :template => 'manifestations/list_identifiers'
        when 'ListRecords'
          render :template => 'manifestations/list_records'
        end
      }
      format.mods
      format.json { render :json => @manifestations }
      format.js
    end
  rescue QueryError => e
  #  render :template => 'manifestations/error.xml', :layout => false
    Rails.logger.info "#{Time.zone.now}\t#{query}\t\t#{current_user.try(:username)}\t#{e}"
  #  return
  end

  # GET /manifestations/1
  # GET /manifestations/1.json
  def show
    if params[:api]
      unless my_networks?
        access_denied; return
      end
    end
    if params[:isbn]
      if @manifestation = Manifestation.find_by_isbn(params[:isbn])
        redirect_to @manifestation
        return
      else
        raise ActiveRecord::RecordNotFound if @manifestation.nil?
      end
    #else
    #  @manifestation = Manifestation.find(params[:id], :include => [:patrons, :expressions, :items])
    end
    @manifestation = @manifestation.versions.find(@version).item if @version

    case params[:mode]
    when 'send_email'
      if user_signed_in?
        Notifier.manifestation_info(current_user, @manifestation).deliver
        flash[:notice] = t('page.sent_email')
        redirect_to manifestation_url(@manifestation)
        return
      else
        access_denied; return
      end
    end

    return if render_mode(params[:mode])

    store_location

    respond_to do |format|
      format.html # show.rhtml
      format.json {
        case params[:mode]
        when 'related'
          render :template => 'manifestations/related'
        else
          render :xml => @manifestation
        end
      }
      format.rdf
      format.oai
      format.mods
      format.json { render :json => @manifestation }
      #format.atom { render :template => 'manifestations/oai_ore' }
      #format.json { render :action => 'mods', :layout => false }
      format.js
    end
  end

  # GET /manifestations/new
  def new
    @manifestation = Manifestation.new
    @original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
    @manifestation.series_statement = @series_statement
    if @manifestation.series_statement
      @manifestation.original_title = @manifestation.series_statement.original_title
      @manifestation.title_transcription = @manifestation.series_statement.title_transcription
    elsif @original_manifestation
      @manifestation.original_title = @original_manifestation.original_title
      @manifestation.title_transcription = @original_manifestation.title_transcription
    elsif @expression
      @manifestation.original_title = @expression.original_title
      @manifestation.title_transcription = @expression.title_transcription
    end
    @manifestation.language = Language.where(:iso_639_1 => @locale).first
    @manifestation = @manifestation.set_serial_number unless params[:mode] == 'attachment'

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @manifestation }
    end
  end

  # GET /manifestations/1/edit
  def edit
    unless current_user.has_role?('Librarian')
      unless params[:mode] == 'tag_edit'
        access_denied; return
      end
    end
    #@manifestation = Manifestation.find(params[:id])
    @original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
    @manifestation.series_statement = @series_statement if @series_statement
    store_location unless params[:mode] == 'tag_edit'
  end

  # POST /manifestations
  # POST /manifestations.json
  def create
    @manifestation = Manifestation.new(params[:manifestation])
    if @manifestation.original_title.blank?
      @manifestation.original_title = @manifestation.attachment_file_name
    end

    respond_to do |format|
      if @manifestation.save
        Manifestation.transaction do
          @original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
          if @original_manifestation
            @manifestation.derived_manifestations << @original_manifestation
          end
          # 雑誌の場合、出版者を自動的に追加
          if @manifestation.series_statement
            @manifestation.create_next_issue_work_and_expression
          end
          if @expression
            @manifestation.expressions << @expression
          end
          if @patron
            @manifestation.patrons << @patron
          end
        end

        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.manifestation'))
        format.html { redirect_to(@manifestation) }
        format.json { render :json => @manifestation, :status => :created, :location => @manifestation }
      else
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @manifestation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /manifestations/1
  # PUT /manifestations/1.json
  def update
    #@manifestation = Manifestation.find(params[:id])
    
    respond_to do |format|
      if @manifestation.update_attributes(params[:manifestation])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.manifestation'))
        format.html { redirect_to @manifestation }
        format.json { head :no_content }
        format.js
      else
        prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @manifestation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /manifestations/1
  # DELETE /manifestations/1.json
  def destroy
    #@manifestation = Manifestation.find(params[:id])
    @manifestation.destroy
    flash[:notice] = t('controller.successfully_deleted', :model => t('activerecord.models.manifestation'))

    respond_to do |format|
      format.html { redirect_to manifestations_url }
      format.json { head :no_content }
    end
  end

  private

  def make_query(query, options = {})
    # TODO: integerやstringもqfに含める
    query = query.to_s.strip
    if options[:mode] == 'recent'
      query = "#{query} created_at_d:[NOW-1MONTH TO NOW]"
    end

    #unless options[:carrier_type].blank?
    #  query = "#{query} carrier_type_s:#{options[:carrier_type]}"
    #end

    #unless options[:library].blank?
    #  library_list = options[:library].split.uniq.join(' and ')
    #  query = "#{query} library_sm:#{library_list}"
    #end

    #unless options[:language].blank?
    #  query = "#{query} language_sm:#{options[:language]}"
    #end

    #unless options[:subject].blank?
    #  query = "#{query} subject_sm:#{options[:subject]}"
    #end

    unless options[:tag].blank?
      query = "#{query} tag_sm:#{options[:tag]}"
    end

    unless options[:creator].blank?
      query = "#{query} creator_text:#{options[:creator]}"
    end

    unless options[:contributor].blank?
      query = "#{query} contributor_text:#{options[:contributor]}"
    end

    unless options[:isbn].blank?
      query = "#{query} isbn_sm:#{options[:isbn]}"
    end

    unless options[:issn].blank?
      query = "#{query} issn_s:#{options[:issn]}"
    end

    unless options[:lccn].blank?
      query = "#{query} lccn_s:#{options[:lccn]}"
    end

    unless options[:nbn].blank?
      query = "#{query} nbn_s:#{options[:nbn]}"
    end

    unless options[:publisher].blank?
      query = "#{query} publisher_text:#{options[:publisher]}"
    end

    unless options[:number_of_pages_at_least].blank? and options[:number_of_pages_at_most].blank?
      number_of_pages = {}
      number_of_pages[:at_least] = options[:number_of_pages_at_least].to_i
      number_of_pages[:at_most] = options[:number_of_pages_at_most].to_i
      number_of_pages[:at_least] = "*" if number_of_pages[:at_least] == 0
      number_of_pages[:at_most] = "*" if number_of_pages[:at_most] == 0

      query = "#{query} number_of_pages_i:[#{number_of_pages[:at_least]} TO #{number_of_pages[:at_most]}]"
    end

    unless options[:pub_date_from].blank? and options[:pub_date_to].blank?
      options[:pub_date_from].to_s.gsub!(/\D/, '')
      options[:pub_date_to].to_s.gsub!(/\D/, '')

      pub_date = {}
      if options[:pub_date_from].blank?
        pub_date[:from] = "*"
      else
        pub_date[:from] = Time.zone.parse(options[:pub_date_from]).beginning_of_day.utc.iso8601 rescue nil
        unless pub_date[:from]
          pub_date[:from] = Time.zone.parse(Time.mktime(options[:pub_date_from]).to_s).beginning_of_day.utc.iso8601
        end
      end

      if options[:pub_date_to].blank?
        pub_date[:to] = "*"
      else
        pub_date[:to] = Time.zone.parse(options[:pub_date_to]).tomorrow.beginning_of_day.utc.iso8601 rescue nil
        unless pub_date[:to]
          pub_date[:to] = Time.zone.parse(Time.mktime(options[:pub_date_to]).to_s).beginning_of_day.utc.iso8601
        end
      end
      query = "#{query} date_of_publication_d:[#{pub_date[:from]} TO #{pub_date[:to]}]"
    end

    query = query.strip
    if query == '[* TO *]'
      #  unless params[:advanced_search]
      query = ''
      #  end
    end

    return query
  end

  def set_search_result_order(sort_by, order)
    sort = {}
    # TODO: ページ数や大きさでの並べ替え
    case sort_by
    when 'title'
      sort[:sort_by] = 'sort_title'
      sort[:order] = 'asc'
    when 'pub_date'
      sort[:sort_by] = 'date_of_publication'
      sort[:order] = 'desc'
    else
      # デフォルトの並び方
      sort[:sort_by] = 'created_at'
      sort[:order] = 'desc'
    end
    if order == 'asc'
      sort[:order] = 'asc'
    elsif order == 'desc'
      sort[:order] = 'desc'
    end
    sort
  end

  def render_mode(mode)
    case mode
    when 'barcode'
      barcode = Barby::QrCode.new(@manifestation.id)
      send_data(barcode.to_svg, :disposition => 'inline', :type => 'image/png')
    when 'holding'
      render :partial => 'manifestations/show_holding', :locals => {:manifestation => @manifestation}
    when 'tag_edit'
      render :partial => 'manifestations/tag_edit', :locals => {:manifestation => @manifestation}
    when 'tag_list'
      render :partial => 'manifestations/tag_list', :locals => {:manifestation => @manifestation}
    when 'show_index'
      render :partial => 'manifestations/show_index', :locals => {:manifestation => @manifestation}
    when 'show_authors'
      render :partial => 'manifestations/show_authors', :locals => {:manifestation => @manifestation}
    when 'show_all_authors'
      render :partial => 'manifestations/show_authors', :locals => {:manifestation => @manifestation}
    when 'pickup'
      render :partial => 'manifestations/pickup', :locals => {:manifestation => @manifestation}
    when 'screen_shot'
      if @manifestation.screen_shot
        mime = FileWrapper.get_mime(@manifestation.screen_shot.path)
        send_file @manifestation.screen_shot.path, :type => mime, :disposition => 'inline'
      end
    when 'calil_list'
      render :partial => 'manifestations/calil_list', :locals => {:manifestation => @manifestation}
    else
      false
    end
  end

  def prepare_options
    @carrier_types = CarrierType.all
    @roles = Role.all
    @languages = Language.all
    @frequencies = Frequency.all
    @nii_types = NiiType.all if defined?(NiiType)
  end

  def save_search_history(query, offset = 0, total = 0, user = nil)
    if configatron.write_search_log_to_file
      write_search_log(query, total, user)
    else
      history = SearchHistory.create(:query => query, :user => user, :start_record => offset + 1, :maximum_records => nil, :number_of_records => total)
    end
  end

  def write_search_log(query, total, user)
    SEARCH_LOGGER.info "#{Time.zone.now}\t#{query}\t#{total}\t#{user.try(:username)}\t#{params[:format]}"
  end

end
