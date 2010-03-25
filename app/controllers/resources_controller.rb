class ResourcesController < ApplicationController
  before_filter :has_permission?
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  include OaiController

  # GET /resources
  # GET /resources.xml
  def index
    @oai = check_oai_params(params)
    if Resource.first and Resource.last
      @from_time = Time.zone.parse(params[:from]) rescue Resource.last.updated_at
      @until_time = Time.zone.parse(params[:until]) rescue Resource.first.updated_at
    else
      @from_time = Time.zone.now
      @until_time = Time.zone.now
    end
    if params[:format] == 'oai'
      # OAI-PMHのデフォルトの件数
      per_page = 200
      if current_token = get_resumption_token(params[:resumptionToken])
        page = (current_token[:cursor].to_i + per_page).div(per_page) + 1
      end
      if params[:verb] == 'GetRecord' and params[:identifier]
        resource = Resource.find_by_oai_identifier(params[:identifier])
        redirect_to resource_url(resource, :format => 'oai')
        return
      end
    end

    page ||= params[:page] || 1

    case params[:approved]
    when 'true'
      @resources = Resource.approved(@from_time, @until_time).paginate(:page => page)
    when 'false'
      @resources = Resource.not_approved(@from_time, @until_time).paginate(:page => page)
    else
      if Resource.respond_to?(:search)
        query = params[:query]
        @query = query
        published = true unless current_user.try(:has_role?, 'Librarian')
        search = Sunspot.new_search(Resource)
        from_time = @from_time; until_time = @until_time
        search.build do
          fulltext query
          with(:state).equal_to 'published' if published
          with(:updated_at).greater_than from_time if from_time
          with(:updated_at).less_than until_time if until_time
        end
        search.query.paginate(page.to_i, Resource.per_page)
        @resources = search.execute!.results
      else
        if current_user.try(:has_role?, 'Librarian')
          @resources = Resource.all_record(@from_time, @until_time).paginate(:page => page)
        else
          @resources = Resource.published(@from_time, @until_time).paginate(:page => page)
        end
      end
    end

    set_resumption_token(@resources, @from_time || Resource.last.updated_at, @until_time || Resource.first.updated_at)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
      format.oai  {
        case params[:verb]
        when 'Identify'
          render :template => 'resources/identify'
        when 'ListMetadataFormats'
          render :template => 'resources/list_metadata_formats'
        when 'ListSets'
          @series_statements = SeriesStatement.all
          render :template => 'resources/list_sets'
        when 'ListIdentifiers'
          render :template => 'resources/list_identifiers'
        when 'ListRecords'
          render :template => 'resources/list_records'
        end
      }
    end
  end

  # GET /resources/1
  # GET /resources/1.xml
  def show
    @resource = Resource.find(params[:id])
    unless current_user.try(:has_role?, 'Librarian')
      unless @resource.last_published
        not_found; return
      end
      @resource = @resource.last_published
      unless @resource.last_published.try(:is_readable_by, current_user)
        access_denied; return
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource }
      format.oai
    end
  end

  # GET /resources/new
  # GET /resources/new.xml
  def new
    @resource = Resource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource = Resource.find(params[:id])
  end

  # POST /resources
  # POST /resources.xml
  def create
    @resource = Resource.new(params[:resource])

    respond_to do |format|
      if @resource.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.resource'))
        format.html { redirect_to(@resource) }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @resource = Resource.find(params[:id])
    case params[:commit]
    when t('resource.approve')
      @resource.approve = "1"
    when t('resource.publish')
      @resource.publish = "1"
    end

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.resource'))
        format.html { redirect_to(@resource) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = Resource.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to(resources_url) }
      format.xml  { head :ok }
    end
  end

  def approve_selected
    if current_user
      unless current_user.has_role?('Librarian')
        access_denied
      end
    else
      redirect_to new_user_session_url
      return
    end
    respond_to do |format|
      if params[:to_approved].present?
        resources = params[:to_approved].map {|r| Resource.find_by_id(r)}
      elsif params[:approve] == 'all_resources'
        resources = Resource.all(:conditions => {:state => 'not_approved'})
      end
      if resources.present?
        resources.each do |resource|
          resource.approve = '1'
          resource.save
        end
        flash[:notice] = t('resource.resources_were_approved')
        format.html { redirect_to resources_url(:approved => "false") }
      else
        flash[:notice] = t('resource.select_resources')
        format.html { redirect_to resources_url(:approved => "false") }
      end
    end
  end

  def publish_selected
    if current_user
      unless current_user.has_role?('Librarian')
        access_denied
      end
    else
      redirect_to new_user_session_url
      return
    end
    respond_to do |format|
      if params[:to_published].present?
        resources = params[:to_published].map {|r| Resource.find_by_id(r)}
      elsif params[:publish] == 'all_resources'
        resources = Resource.all(:conditions => {:state => 'approved'})
      end
      if resources.present?
        resources.each do |resource|
          resource.publish = '1'
          resource.save
        end
        flash[:notice] = t('resource.resources_were_published')
        format.html { redirect_to resources_url(:approved => "true") }
      else
        flash[:notice] = t('resource.select_resources')
        format.html { redirect_to resources_url(:approved => "true") }
      end
    end
  end

end
