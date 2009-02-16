class ShelvesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  require_role 'Administrator', :except => [:index, :show]
  before_filter :get_library
  before_filter :get_libraries, :only => [:new, :edit, :create, :update]

  # GET /shelves
  # GET /shelves.xml
  def index
    if @library
      @shelves = @library.shelves.paginate(:page => params[:page], :include => :library, :order => ['shelves.position'])
    else
      @shelves = Shelf.paginate(:all, :page => params[:page], :include => :library, :order => ['shelves.position'])
    end
    if params[:select]
      render :partial => 'select_form'
      return
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @shelves.to_xml }
    end
  end

  # GET /shelves/1
  # GET /shelves/1.xml
  def show
    @shelf = Shelf.find(params[:id], :include => :library)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @shelf.to_xml }
    end
  end

  # GET /shelves/new
  def new
    @library = Library.find(:first) if @library.nil?
    @shelf = Shelf.new
  end

  # GET /shelves/1;edit
  def edit
    @shelf = Shelf.find(params[:id], :include => :library)
  end

  # POST /shelves
  # POST /shelves.xml
  def create
    @shelf = Shelf.new(params[:shelf])
    #@shelf.library = @library

    respond_to do |format|
      if @shelf.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.shelf'))
        format.html { redirect_to shelf_url(@shelf) }
        format.xml  { render :xml => @shelf, :status => :created, :location => library_shelf_url(@shelf.library.short_name, @shelf) }
      else
        @library = Library.find(:first) if @shelf.library.nil?
        format.html { render :action => "new" }
        format.xml  { render :xml => @shelf.errors.to_xml }
      end
    end
  end

  # PUT /shelves/1
  # PUT /shelves/1.xml
  def update
    @shelf = Shelf.find(params[:id])

    if @shelf and params[:position]
      @shelf.insert_at(params[:position])
      redirect_to library_shelves_url(@shelf.library.short_name)
      return
    end

    respond_to do |format|
      if @shelf.update_attributes(params[:shelf])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.shelf'))
        format.html { redirect_to library_shelf_url(@shelf.library.short_name, @shelf) }
        format.xml  { head :ok }
      else
        @library = Library.find(:first) if @library.nil?
        format.html { render :action => "edit" }
        format.xml  { render :xml => @shelf.errors.to_xml }
      end
    end
  end

  # DELETE /shelves/1
  # DELETE /shelves/1.xml
  def destroy
    @shelf = Shelf.find(params[:id])
    raise if @shelf.id == 1

    @shelf.destroy

    respond_to do |format|
      format.html { redirect_to library_shelves_url(@shelf.library.short_name) }
      format.xml  { head :ok }
    end
  rescue
    access_denied
  end

end
