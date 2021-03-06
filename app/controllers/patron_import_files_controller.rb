class PatronImportFilesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource

  # GET /patron_import_files
  # GET /patron_import_files.json
  def index
    @patron_import_files = PatronImportFile.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @patron_import_files }
    end
  end

  # GET /patron_import_files/1
  # GET /patron_import_files/1.json
  def show
    @patron_import_file = PatronImportFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @patron_import_file }
      format.download  { send_file @patron_import_file.patron_import.path, :filename => @patron_import_file.patron_import_file_name, :type => @patron_import_file.patron_import_content_type, :disposition => 'inline' }
    end
  end

  # GET /patron_import_files/new
  # GET /patron_import_files/new.json
  def new
    @patron_import_file = PatronImportFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @patron_import_file }
    end
  end

  # GET /patron_import_files/1/edit
  def edit
    @patron_import_file = PatronImportFile.find(params[:id])
  end

  # POST /patron_import_files
  # POST /patron_import_files.json
  def create
    @patron_import_file = PatronImportFile.new(params[:patron_import_file])
    @patron_import_file.user = current_user

    respond_to do |format|
      if @patron_import_file.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.patron_import_file'))
        format.html { redirect_to(@patron_import_file) }
        format.json { render :json => @patron_import_file, :status => :created, :location => @patron_import_file }
      else
        format.html { render :action => "new" }
        format.json { render :json => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  #rescue
  #  flash[:notice] = ('Invalid file.')
  #  redirect_to new_resource_import_file_url
  end

  # PUT /patron_import_files/1
  # PUT /patron_import_files/1.json
  def update
    @patron_import_file = PatronImportFile.find(params[:id])

    respond_to do |format|
      if @patron_import_file.update_attributes(params[:patron_import_file])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.patron_import_file'))
        format.html { redirect_to(@patron_import_file) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /patron_import_files/1
  # DELETE /patron_import_files/1.json
  def destroy
    @patron_import_file = PatronImportFile.find(params[:id])
    @patron_import_file.destroy

    respond_to do |format|
      format.html { redirect_to(patron_import_files_url) }
      format.json { head :no_content }
    end
  end
end
