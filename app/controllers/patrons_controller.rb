class PatronsController < ApplicationController
  before_filter :has_permission?
  before_filter :get_user_if_nil
  before_filter :get_work, :get_expression, :get_manifestation, :get_item
  before_filter :get_patron, :only => :index
  before_filter :get_patron_merge_list
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :store_location
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  
  # GET /patrons
  # GET /patrons.xml
  def index
    #session[:params] = {} unless session[:params]
    #session[:params][:patron] = params
    # 最近追加されたパトロン
    #@query = params[:query] ||= "[* TO *]"
    query = params[:query].to_s.strip
    @query = query.dup
    query = query.gsub('　', ' ')
    order = nil
    @count = {}

    search = Sunspot.new_search(Patron)

    if params[:mode] == 'recent'
      query = "#{query} created_at_d: [NOW-1MONTH TO NOW]"
    end
    unless query.blank?
      search.query.keywords = query
    end
    unless params[:mode] == 'add'
      search.query.add_restriction(:work_ids, :equal_to, @work.id) if @work
      search.query.add_restriction(:expression_ids, :equal_to, @expression.id) if @expression
      search.query.add_restriction(:manifestation_ids, :equal_to, @manifestation.id) if @manifestation
      search.query.add_restriction(:original_patron_ids, :equal_to, @patron.id) if @patron
      search.query.add_restriction(:patron_merge_ids, :equal_to, @patron_merge_list.id) if @patron_merge_list
    end
    if logged_in?
      unless current_user.has_role?('Librarian')
        search.query.add_restriction(:required_role_id, :less_than, 2)
      else
        search.query.add_restriction(:required_role_id, :equal_to, 1)
      end
    end
    page = params[:page] || 1
    begin
      search.query.paginate(page.to_i, Patron.per_page)
      @patrons = search.execute!.results
    rescue RSolr::RequestError
      @patrons = WillPaginate::Collection.create(1,1,0) do end
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @patrons }
      format.rss  { render :layout => false }
      format.atom
      format.json { render :json => @patrons }
    end
  end

  # GET /patrons/1
  # GET /patrons/1.xml
  def show
    case
    when @work
      @patron = @work.patrons.find(params[:id])
    when @expression
      @patron = @expression.patrons.find(params[:id])
    when @manifestation
      @patron = @manifestation.patrons.find(params[:id])
    when @item
      @patron = @item.patrons.find(params[:id])
    else
      @patron = Patron.find(params[:id])
    end

    #@involved_manifestations = @patron.involved_manifestations.paginate(:page => params[:page], :order => 'date_of_publication DESC')
    @works = @patron.works.paginate(:page => params[:work_list_page])
    @expressions = @patron.expressions.paginate(:page => params[:expression_list_page])
    @manifestations = @patron.manifestations.paginate(:page => params[:manifestation_list_page], :order => 'date_of_publication DESC')

    canonical_url patron_url(@patron)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @patron }
      format.js {
        render :update do |page|
          page.replace_html 'work', :partial => 'work_list', :locals => {:works => @works} if params[:work_list_page]
          page.replace_html 'expression', :partial => 'expression_list', :locals => {:expressions => @expressions} if params[:expression_list_page]
          page.replace_html 'manifestation', :partial => 'manifestation_list', :locals => {:manifestations => @manifestations} if params[:manifestation_list_page]
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # GET /patrons/new
  def new
    unless current_user.has_role?('Librarian')
      unless current_user == @user
        access_denied; return
      end
    end
    @patron = Patron.new
    if @user
      @patron.user = @user
    end
    prepare_options

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @patron }
    end
  end

  # GET /patrons/1;edit
  def edit
    @patron = Patron.find(params[:id])
    prepare_options
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # POST /patrons
  # POST /patrons.xml
  def create
    @patron = Patron.new(params[:patron])
    if @patron.user_id
      @patron.user = User.find(@patron.user_id) rescue nil
    end
    unless current_user.has_role?('Librarian')
      if @patron.user != current_user
        access_denied; return
      end
    end

    respond_to do |format|
      if @patron.save
        @patron.index
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.patron'))
        case
        when @work
          @work.patrons << @patron
          format.html { redirect_to patron_work_url(@patron, @work) }
          format.xml  { head :created, :location => patron_work_url(@patron, @work) }
        when @expression
          @expression.patrons << @patron
          format.html { redirect_to patron_expression_url(@patron, @expression) }
          format.xml  { head :created, :location => patron_expression_url(@patron, @expression) }
        when @manifestation
          @manifestation.patrons << @patron
          format.html { redirect_to patron_manifestation_url(@patron, @manifestation) }
          format.xml  { head :created, :location => patron_manifestation_url(@patron, @manifestation) }
        else
          format.html { redirect_to(@patron) }
          format.xml  { render :xml => @patron, :status => :created, :location => @patron }
        end
      else
        prepare_options
        format.html { render :action => "new" }
        format.xml  { render :xml => @patron.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /patrons/1
  # PUT /patrons/1.xml
  def update
    @patron = Patron.find(params[:id])

    respond_to do |format|
      if @patron.update_attributes(params[:patron])
        @patron.index
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.patron'))
        format.html { redirect_to patron_url(@patron) }
        format.xml  { head :ok }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.xml  { render :xml => @patron.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # DELETE /patrons/1
  # DELETE /patrons/1.xml
  def destroy
    @patron = Patron.find(params[:id])

    if @patron.user
      if @patron.user.has_role?('Librarian')
        unless current_user.has_role?('Administrator')
          access_denied
          return
        end
      end
    end

    @patron.destroy
    @patron.remove_from_index

    respond_to do |format|
      format.html { redirect_to patrons_url }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  private

  #def get_patron
  #  case
  #  when @work
  #    @patron = @work.patrons.find(params[:id])
  #  when @expression
  #    @patron = @expression.patrons.find(params[:id])
  #  when @manifestation
  #    @patron = @manifestation.patrons.find(params[:id])
  #  when @item
  #    @patron = @item.patrons.find(params[:id])
  #  else
  #    @patron = Patron.find(params[:id])
  #  end
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  #end

  def prepare_options
    @patron_types = PatronType.find(:all)
    @countries = Country.find(:all)
    @roles = Role.find(:all)
    @languages = Rails.cache.fetch('Language.all'){Language.all}
  end

end
