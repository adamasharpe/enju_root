# -*- encoding: utf-8 -*-
class ExpressionsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_user_if_nil
  before_filter :get_patron
  before_filter :get_work, :get_manifestation
  before_filter :get_expression, :only => :index
  before_filter :get_expression_merge_list
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :get_version, :only => [:show]
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /expressions
  # GET /expressions.json
  def index
    query = params[:query].to_s.strip
    search = Sunspot.new_search(Expression)
    @count = {}
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      #query = "#{query} frequency_of_issue_id: [2 TO *]" if params[:view] == 'serial'
      search.build do
        fulltext query
      end
    end

    set_role_query(current_user, search)

    unless params[:mode] == 'add'
      manifestation = @manifestation
      patron = @patron
      work = @work
      expression = @expression
      expression_merge_list = @expression_merge_list
      search.build do
        with(:manifestation_ids).equal_to manifestation.id if manifestation
        with(:patron_ids).equal_to patron.id if patron
        with(:work_id).equal_to work.id if work
        with(:original_expression_ids).equal_to expression.id if expression
        with(:expression_merge_list_ids).equal_to expression_merge_list.id if expression_merge_list
      end
    end

    role = current_user.try(:role) || Role.find('Guest')
    search.build do
      with(:required_role_id).less_than role.id
    end

    page = params[:page] || 1
    search.query.paginate(page.to_i, Expression.per_page)
    @expressions = search.execute!.results
    @count[:total] = @expressions.total_entries

    respond_to do |format|
      format.html # index.rhtml
      format.json { render :json => @expressions }
      format.atom
    end
  end

  # GET /expressions/1
  # GET /expressions/1.json
  def show
    case when @work
      @expression = @work.expressions.find(params[:id])
    when @manifestation
      @expression = @manifestation.expressions.find(params[:id])
    when @patron
      @expression = @patron.expressions.find(params[:id])
    #else
    #  @expression = Expression.find(params[:id])
    end
    @expression = @expression.versions.find(@version).item if @version

    respond_to do |format|
      format.html # show.rhtml
      format.json { render :json => @expression }
    end
  end

  # GET /expressions/new
  def new
    #unless @work
    #  flash[:notice] = t('expression.specify_work')
    #  redirect_to works_path
    #  return
    #end
    @expression = Expression.new
    if @work
      @expression.original_title = @work.original_title
      @expression.title_transcription = @work.title_transcription
    end
    @expression.language = Language.where(:iso_639_1 => @locale).first

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @expression }
    end
  end

  # GET /expressions/1/edit
  def edit
    #@expression = Expression.find(params[:id])
  end

  # POST /expressions
  # POST /expressions.json
  def create
    unless @work
      flash[:notice] = t('expression.specify_work')
      redirect_to works_path
      return
    end
    @expression = Expression.new(params[:expression])

    respond_to do |format|
      if @expression.save
        Expression.transaction do
          @work.expressions << @expression
          #if @expression.serial?
          #  @expression.patrons << @work.patrons
          #end
        end

        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.expression'))
        format.html { redirect_to @expression }
        format.json { render :json => @expression, :status => :created, :location => @expression }
      else
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @expression.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /expressions/1
  # PUT /expressions/1.json
  def update
    params[:issn] = params[:issn].gsub(/\D/, "") if params[:issn]

    respond_to do |format|
      if @expression.update_attributes(params[:expression])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.expression'))
        format.html { redirect_to expression_url(@expression) }
        format.json { head :no_content }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @expression.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /expressions/1
  # DELETE /expressions/1.json
  def destroy
    @expression.destroy

    respond_to do |format|
      flash[:notice] = t('controller.successfully_deleted', :model => t('activerecord.models.expression'))
      format.html { redirect_to expressions_url }
      format.json { head :no_content }
    end
  end

  private
  def prepare_options
    if Rails.env == 'production'
      @content_types = Rails.cache.fetch('ContentType.all'){ContentType.all}
      @languages = Language.all_cache
      @roles = Role.all
    else
      @content_types = ContentType.all
      @languages = Language.all
      @roles = Role.all
    end
  end
end
