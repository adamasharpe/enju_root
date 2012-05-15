class ShelvesController < ApplicationController
  load_and_authorize_resource
  before_filter :get_library
  before_filter :get_libraries, :only => [:new, :edit, :create, :update]
  #cache_sweeper :page_sweeper, :only => [:create, :update, :destroy]

  # GET /shelves
  # GET /shelves.json
  def index
    if params[:mode] == 'select'
      if @library
        @shelves = @library.shelves
      else
        @shelves = Shelf.real
      end
      render :partial => 'select_form'
      return
    else
      if @library
        @shelves = @library.shelves.order('shelves.position').includes(:library).paginate(:page => params[:page])
      else
        @shelves = Shelf.order('shelves.position').includes(:library).paginate(:page => params[:page])
      end
    end

    respond_to do |format|
      format.html # index.rhtml
      format.json { render :json => @shelves }
    end
  end

  # GET /shelves/1
  # GET /shelves/1.json
  def show
    @shelf = Shelf.find(params[:id], :include => :library)

    respond_to do |format|
      format.html # show.rhtml
      format.json { render :json => @shelf }
    end
  end

  # GET /shelves/new
  def new
    @library = Library.web if @library.nil?
    @shelf = Shelf.new
    @shelf.library = @library
    #@shelf.user = current_user
  end

  # GET /shelves/1/edit
  def edit
    @shelf = Shelf.find(params[:id], :include => :library)
  end

  # POST /shelves
  # POST /shelves.json
  def create
    @shelf = Shelf.new(params[:shelf])
    if @library
      @shelf.library = @library
    else
      @shelf.library = Library.web #unless current_user.has_role?('Librarian')
    end

    respond_to do |format|
      if @shelf.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.shelf'))
        format.html { redirect_to shelf_url(@shelf) }
        format.json { render :json => @shelf, :status => :created, :location => library_shelf_url(@shelf.library, @shelf) }
      else
        @library = Library.first if @shelf.library.nil?
        format.html { render :action => "new" }
        format.json { render :json => @shelf.errors }
      end
    end
  end

  # PUT /shelves/1
  # PUT /shelves/1.json
  def update
    @shelf.library = @library if @library

    if params[:position]
      @shelf.insert_at(params[:position])
      redirect_to library_shelves_url(@shelf.library)
      return
    end

    respond_to do |format|
      if @shelf.update_attributes(params[:shelf])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.shelf'))
        format.html { redirect_to library_shelf_url(@shelf.library, @shelf) }
        format.json { head :no_content }
      else
        @library = Library.first if @library.nil?
        format.html { render :action => "edit" }
        format.json { render :json => @shelf.errors }
      end
    end
  end

  # DELETE /shelves/1
  # DELETE /shelves/1.json
  def destroy
    if @shelf.id == 1
      access_denied; return
    end
    @shelf.destroy

    respond_to do |format|
      format.html { redirect_to library_shelves_url(@shelf.library.name) }
      format.json { head :no_content }
    end
  end
end
