class ClassificationTypesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource

  # GET /classification_types
  # GET /classification_types.xml
  def index
    @classification_types = ClassificationType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @classification_types }
    end
  end

  # GET /classification_types/1
  # GET /classification_types/1.xml
  def show
    @classification_type = ClassificationType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @classification_type }
    end
  end

  # GET /classification_types/new
  # GET /classification_types/new.xml
  def new
    @classification_type = ClassificationType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @classification_type }
    end
  end

  # GET /classification_types/1/edit
  def edit
    @classification_type = ClassificationType.find(params[:id])
  end

  # POST /classification_types
  # POST /classification_types.xml
  def create
    @classification_type = ClassificationType.new(params[:classification_type])

    respond_to do |format|
      if @classification_type.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.classification_type'))
        format.html { redirect_to(@classification_type) }
        format.xml  { render :xml => @classification_type, :status => :created, :location => @classification_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @classification_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /classification_types/1
  # PUT /classification_types/1.xml
  def update
    @classification_type = ClassificationType.find(params[:id])

    if @classification_type and params[:position]
      @classification_type.insert_at(params[:position])
      redirect_to classification_types_url
      return
    end

    respond_to do |format|
      if @classification_type.update_attributes(params[:classification_type])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.classification_type'))
        format.html { redirect_to(@classification_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @classification_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /classification_types/1
  # DELETE /classification_types/1.xml
  def destroy
    @classification_type = ClassificationType.find(params[:id])
    @classification_type.destroy

    respond_to do |format|
      format.html { redirect_to(classification_types_url) }
      format.xml  { head :ok }
    end
  end
end
