class InventoryFilesController < ApplicationController
  before_filter :login_required
  require_role 'Librarian'

  # GET /inventory_files
  # GET /inventory_files.xml
  def index
    @inventory_files = InventoryFile.paginate(:all, :page => params[:page], :per_page => @per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @inventory_files }
    end
  end

  # GET /inventory_files/1
  # GET /inventory_files/1.xml
  def show
    @inventory_file = InventoryFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @inventory_file }
    end
  end

  # GET /inventory_files/new
  # GET /inventory_files/new.xml
  def new
    @inventory_file = InventoryFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @inventory_file }
    end
  end

  # GET /inventory_files/1/edit
  def edit
    @inventory_file = InventoryFile.find(params[:id])
  end

  # POST /inventory_files
  # POST /inventory_files.xml
  def create
    @inventory_file = InventoryFile.new(params[:inventory_file])

    respond_to do |format|
      if @inventory_file.save
        flash[:notice] = ('InventoryFile was successfully created.')
        @inventory_file.import
        format.html { redirect_to(@inventory_file) }
        format.xml  { render :xml => @inventory_file, :status => :created, :location => @inventory_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @inventory_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /inventory_files/1
  # PUT /inventory_files/1.xml
  def update
    @inventory_file = InventoryFile.find(params[:id])

    respond_to do |format|
      if @inventory_file.update_attributes(params[:inventory_file])
        flash[:notice] = ('InventoryFile was successfully updated.')
        format.html { redirect_to(@inventory_file) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @inventory_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory_files/1
  # DELETE /inventory_files/1.xml
  def destroy
    @inventory_file = InventoryFile.find(params[:id])
    @inventory_file.destroy

    respond_to do |format|
      format.html { redirect_to(inventory_files_url) }
      format.xml  { head :ok }
    end
  end
end
