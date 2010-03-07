class ResourcesController < ApplicationController
  before_filter :has_permission?
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /resources
  # GET /resources.xml
  def index
    case params[:approved]
    when 'true'
      @resources = Resource.approved.paginate(:page => params[:page])
    when 'false'
      @resources = Resource.not_approved.paginate(:page => params[:page])
    else
      query = params[:query]
      @query = query
      page = params[:page] || 1
      search = Sunspot.new_search(Resource)
      search.build do
        fulltext query
      end
      search.query.paginate(page.to_i, Resource.per_page)
      @resources = search.execute!.results
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
    end
  end

  # GET /resources/1
  # GET /resources/1.xml
  def show
    @resource = Resource.find(params[:id])
    unless current_user.try(:has_role?, 'Librarian')
      unless @resource.last_approved
        not_found; return
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource }
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
        flash[:notice] = 'Resource was successfully created.'
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

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Resource was successfully updated.'
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
    respond_to do |format|
      if params[:to_approved].present?
        resources = params[:to_approved].map {|r| Resource.find_by_id(r)}
      elsif params[:approve] == 'all_resources'
        resources = Resource.not_approved
      end
      if resources.present?
        resources.each do |resource|
          resource.update_attributes!(:approved => true)
        end
        flash[:notice] = 'Resources were approved.'
        format.html { redirect_to resources_url }
      else
        flash[:notice] = 'Select resources.'
        format.html { redirect_to resources_url }
      end
    end
  end
end
