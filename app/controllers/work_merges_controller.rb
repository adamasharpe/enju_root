class WorkMergesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :get_work, :get_work_merge_list

  # GET /work_merges
  # GET /work_merges.xml
  def index
    if @work
      @work_merges = @work.work_merges.paginate(:all, :page => params[:page], :order => ['work_merges.id'])
    elsif @work_merge_list
      @work_merges = @work_merge_list.work_merges.paginate(:all, :page => params[:page], :include => 'work', :order => ['work_merges.id'])
    else
      @work_merges = WorkMerge.paginate(:all, :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @work_merges }
    end
  end

  # GET /work_merges/1
  # GET /work_merges/1.xml
  def show
    @work_merge = WorkMerge.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @work_merge }
    end
  end

  # GET /work_merges/new
  # GET /work_merges/new.xml
  def new
    @work_merge = WorkMerge.new
    @work_merge.work = @work if @work

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @work_merge }
    end
  end

  # GET /work_merges/1/edit
  def edit
    @work_merge = WorkMerge.find(params[:id])
  end

  # POST /work_merges
  # POST /work_merges.xml
  def create
    @work_merge = WorkMerge.new(params[:work_merge])

    respond_to do |format|
      if @work_merge.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.work_merge'))
        format.html { redirect_to(@work_merge) }
        format.xml  { render :xml => @work_merge, :status => :created, :location => @work_merge }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @work_merge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /work_merges/1
  # PUT /work_merges/1.xml
  def update
    @work_merge = WorkMerge.find(params[:id])

    respond_to do |format|
      if @work_merge.update_attributes(params[:work_merge])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.work_merge'))
        format.html { redirect_to(@work_merge) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @work_merge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /work_merges/1
  # DELETE /work_merges/1.xml
  def destroy
    @work_merge = WorkMerge.find(params[:id])
    @work_merge.destroy

    respond_to do |format|
      format.html { redirect_to(work_merges_url) }
      format.xml  { head :ok }
    end
  end
end
