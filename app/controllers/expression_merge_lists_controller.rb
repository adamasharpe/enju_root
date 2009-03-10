class ExpressionMergeListsController < ApplicationController
  before_filter :check_client_ip_address
  before_filter :has_permission?

  # GET /expression_merge_lists
  # GET /expression_merge_lists.xml
  def index
    @expression_merge_lists = ExpressionMergeList.paginate(:all, :page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @expression_merge_lists }
    end
  end

  # GET /expression_merge_lists/1
  # GET /expression_merge_lists/1.xml
  def show
    @expression_merge_list = ExpressionMergeList.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @expression_merge_list }
    end
  end

  # GET /expression_merge_lists/new
  # GET /expression_merge_lists/new.xml
  def new
    @expression_merge_list = ExpressionMergeList.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @expression_merge_list }
    end
  end

  # GET /expression_merge_lists/1/edit
  def edit
    @expression_merge_list = ExpressionMergeList.find(params[:id])
  end

  # POST /expression_merge_lists
  # POST /expression_merge_lists.xml
  def create
    @expression_merge_list = ExpressionMergeList.new(params[:expression_merge_list])

    respond_to do |format|
      if @expression_merge_list.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.expression_merge_list'))
        format.html { redirect_to(@expression_merge_list) }
        format.xml  { render :xml => @expression_merge_list, :status => :created, :location => @expression_merge_list }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @expression_merge_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /expression_merge_lists/1
  # PUT /expression_merge_lists/1.xml
  def update
    @expression_merge_list = ExpressionMergeList.find(params[:id])

    respond_to do |format|
      if @expression_merge_list.update_attributes(params[:expression_merge_list])
        if params[:mode] == 'merge'
          selected_expression = Expression.find(params[:selected_expression_id]) rescue nil
          if selected_expression
            @expression_merge_list.merge_expressions(selected_expression)
            flash[:notice] = ('Expressions are merged successfully.')
          else
            flash[:notice] = ('Specify expression id.')
            redirect_to expression_merge_list_url(@expression_merge_list)
            return
          end
        else
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.expression_merge_list'))
        end
        format.html { redirect_to(@expression_merge_list) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @expression_merge_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /expression_merge_lists/1
  # DELETE /expression_merge_lists/1.xml
  def destroy
    @expression_merge_list = ExpressionMergeList.find(params[:id])
    @expression_merge_list.destroy

    respond_to do |format|
      format.html { redirect_to(expression_merge_lists_url) }
      format.xml  { head :ok }
    end
  end
end
