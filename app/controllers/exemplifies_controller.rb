class ExemplifiesController < ApplicationController
  load_and_authorize_resource
  before_filter :get_manifestation, :get_item
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  #cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]

  # GET /exemplifies
  # GET /exemplifies.json
  def index
    @exemplifies = Exemplify.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @exemplifies }
    end
  end

  # GET /exemplifies/1
  # GET /exemplifies/1.json
  def show
    @exemplify = Exemplify.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @exemplify }
    end
  end

  # GET /exemplifies/new
  # GET /exemplifies/new.json
  def new
    @exemplify = Exemplify.new
    @exemplify.manifestation = @manifestation
    @exemplify.item = @item

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @exemplify }
    end
  end

  # GET /exemplifies/1/edit
  def edit
    @exemplify = Exemplify.find(params[:id])
  end

  # POST /exemplifies
  # POST /exemplifies.json
  def create
    @exemplify = Exemplify.new(params[:exemplify])

    respond_to do |format|
      if @exemplify.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.exemplify'))
        format.html { redirect_to(@exemplify) }
        format.json { render :json => @exemplify, :status => :created, :location => @exemplify }
      else
        format.html { render :action => "new" }
        format.json { render :json => @exemplify.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /exemplifies/1
  # PUT /exemplifies/1.json
  def update
    @exemplify = Exemplify.find(params[:id])

    if @manifestation and params[:position]
      @exemplify.insert_at(params[:position])
      redirect_to manifestation_exemplifies_url(@manifestation)
      return
    end

    respond_to do |format|
      if @exemplify.update_attributes(params[:exemplify])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.exemplify'))
        case when @manifestation
          format.html { redirect_to manifestation_items_path(@exemplify.manifestation) }
          format.json { head :no_content }
        when @item
          format.html { redirect_to @exemplify.item }
          format.json { head :no_content }
        else
          format.html { redirect_to(@exemplify) }
          format.json { head :no_content }
        end
      else
        format.html { render :action => "edit" }
        format.json { render :json => @exemplify.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /exemplifies/1
  # DELETE /exemplifies/1.json
  def destroy
    @exemplify = Exemplify.find(params[:id])
    @exemplify.destroy

    respond_to do |format|
      case when @manifestation
        format.html { redirect_to manifestation_items_path(@exemplify.manifestation) }
        format.json { head :no_content }
      when @item
        format.html { redirect_to @exemplify.item }
        format.json { head :no_content }
      else
        format.html { redirect_to exemplifies_url }
        format.json { head :no_content }
      end
    end
  end
end
