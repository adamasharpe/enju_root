class PatronsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  require_role 'Librarian', :only => [:new, :create, :destroy]
  before_filter :get_work, :get_expression, :get_manifestation, :get_item
  before_filter :get_patron_merge_list
  before_filter :get_patron, :except => [:index, :new, :create]
  before_filter :authorized_content, :only => [:edit, :create, :update, :destroy]
  before_filter :store_location
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  
  # GET /patrons
  # GET /patrons.xml
  def index
    session[:params] = {} unless session[:params]
    session[:params][:patron] = params
    # 最近追加されたパトロン
    if params[:recent]
      @query = "[* TO *] created_at:[#{1.month.ago.utc.iso8601} TO #{Time.zone.now.iso8601}]"
    elsif params[:query]
      #@query = params[:query] ||= "[* TO *]"
      @query = params[:query].to_s.strip
    end
    browse = nil
    order = nil
    @count = {}

    query = @query.to_s.strip
    if logged_in?
      unless current_user.has_role?('Librarian')
        query += " access_role_id: [* TO 2]"
      end
    else
      query += " access_role_id: 1"
    end

    unless query.blank?

      unless params[:mode] == 'add'
        query += " work_ids: #{@work.id}" if @work
        query += " expression_ids: #{@expression.id}" if @expression
        query += " manifestation_ids: #{@manifestation.id}" if @manifestation
        query += " patron_merge_list_ids: #{@patron_merge_list.id}" if @patron_merge_list
      end

      @patrons = Patron.paginate_by_solr(query, :order => order, :page => params[:page], :per_page => @per_page).compact
      @count[:query_result] = @patrons.total_entries
      @patrons = Patron.paginate_by_solr(query, :page => params[:page], :per_page => @per_page, :order => 'updated_at desc').compact
    else
      case
      when @work
        @patrons = @work.patrons.paginate(:page => params[:page], :per_page => @per_page)
      when @expression
        @patrons = @expression.patrons.paginate(:page => params[:page], :per_page => @per_page)
      when @manifestation
        @patrons = @manifestation.patrons.paginate(:page => params[:page], :per_page => @per_page)
      when @patron_merge_list
        @patrons = @patron_merge_list.patrons.paginate(:page => params[:page], :per_page => @per_page)
      else
        @patrons = Patron.paginate(:all, :page => params[:page], :per_page => @per_page)
      end

    end

    @startrecord = (params[:page].to_i - 1) * Patron.per_page + 1
    @startrecord = 1 if @startrecord < 1

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @patrons }
      format.rss  { render :layout => false }
      format.atom
    end
  end

  # GET /patrons/1
  # GET /patrons/1.xml
  def show
    #@patron = Patron.find(params[:id])

    unless @patron.check_access_role(current_user)
      access_denied
      return
    end

    @involved_manifestations = @patron.involved_manifestations.paginate(:page => params[:page], :per_page => 10, :order => 'date_of_publication DESC')
    @publications = @patron.manifestations.paginate(:page => params[:page], :per_page => 10, :order => 'date_of_publication DESC')

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @patron }
    end
  end

  # GET /patrons/new
  def new
    @patron = Patron.new
    unless @patron.check_access_role(current_user)
      access_denied
      return
    end
    @patron_types = PatronType.find(:all, :order => :position)
    @languages = Language.find(:all, :order => :position)
    @countries = Country.find(:all, :order => :position)
    @roles = Role.find(:all)
  end

  # GET /patrons/1;edit
  def edit
    #@patron = Patron.find(params[:id])
    unless current_user.has_role?('Librarian')
      unless @patron.check_access_role(current_user)
        access_denied
        return
      end
    end
    unless @patron.check_access_role(current_user)
      access_denied
      return
    end
    @patron_types = PatronType.find(:all, :order => :position)
    @languages = Language.find(:all, :order => :position)
    @countries = Country.find(:all, :order => :position)
    @roles = Role.find(:all)
  end

  # POST /patrons
  # POST /patrons.xml
  def create
    @patron = Patron.new(params[:patron])

    respond_to do |format|
      if @patron.save
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
          format.html { redirect_to patron_url(@patron) }
          format.xml  { head :created, :location => patron_url(@patron) }
        end
      else
        @patron_types = PatronType.find(:all, :order => :position)
        @languages = Language.find(:all, :order => :position)
        @countries = Country.find(:all, :order => :position)
        @roles = Role.find(:all)
        format.html { render :action => "new" }
        format.xml  { render :xml => @patron.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /patrons/1
  # PUT /patrons/1.xml
  def update
    #@patron = Patron.find(params[:id])
    unless @patron.check_access_role(current_user)
      access_denied
      return
    end

    respond_to do |format|
      if @patron.update_attributes(params[:patron])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.patron'))
        format.html { redirect_to patron_url(@patron) }
        format.xml  { head :ok }
      else
        @patron_types = PatronType.find(:all, :order => :position)
        @languages = Language.find(:all, :order => :position)
        @countries = Country.find(:all, :order => :position)
        @roles = Role.find(:all)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @patron.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /patrons/1
  # DELETE /patrons/1.xml
  def destroy
    #@patron = Patron.find(params[:id])
    unless @patron.check_access_role(current_user)
      access_denied
      return
    end

    if @patron.user
      if @patron.user.has_role?('Librarian')
        unless current_user.has_role?('Administrator')
          access_denied
          return
        end
      end
    end

    @patron.destroy

    respond_to do |format|
      format.html { redirect_to patrons_url }
      format.xml  { head :ok }
    end
  end

  private

  def get_patron
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
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def authorized_content
    unless current_user.has_role?('Librarian')
      unless @patron.user == current_user
        access_denied
        return
      end
    end
  end
end
