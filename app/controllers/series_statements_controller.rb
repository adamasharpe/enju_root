# -*- encoding: utf-8 -*-
class SeriesStatementsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_work, :only => [:index, :new, :edit]
  before_filter :get_manifestation, :only => [:index, :new, :edit]
  #cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /series_statements
  # GET /series_statements.json
  def index
    search = Sunspot.new_search(SeriesStatement)
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
      end
    end
    #work = @work
    manifestation = @manifestation
    unless params[:mode] == 'add'
      search.build do
      #  with(:work_id).equal_to work.id if work
        with(:manifestation_ids).equal_to manifestation.id if manifestation
      end
    end
    page = params[:page] || 1
    search.query.paginate(page.to_i, SeriesStatement.default_per_page)
    @series_statements = search.execute!.results

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @series_statements }
    end
  end

  # GET /series_statements/1
  # GET /series_statements/1.json
  def show
    @series_statement = SeriesStatement.find(params[:id])
    @manifestations = @series_statement.manifestations.page(params[:manifestation_page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @series_statement }
      format.js
    end
  end

  # GET /series_statements/new
  # GET /series_statements/new.json
  def new
    @series_statement = SeriesStatement.new
    @series_statement.work = @work if @work
    @series_statement.manifestation_id = @manifestation.id if @manifestation

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @series_statement }
    end
  end

  # GET /series_statements/1/edit
  def edit
    @series_statement = SeriesStatement.find(params[:id])
    @series_statement.work = @work if @work
  end

  # POST /series_statements
  # POST /series_statements.json
  def create
    @series_statement = SeriesStatement.new(params[:series_statement])
    manifestation = Manifestation.find(@series_statement.manifestation_id) rescue nil

    respond_to do |format|
      if @series_statement.save
        @series_statement.manifestations << manifestation if manifestation
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.series_statement'))
        format.html { redirect_to(@series_statement) }
        format.json { render :json => @series_statement, :status => :created, :location => @series_statement }
      else
        format.html { render :action => "new" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /series_statements/1
  # PUT /series_statements/1.json
  def update
    @series_statement = SeriesStatement.find(params[:id])

    if params[:position]
      @series_statement.insert_at(params[:position])
      redirect_to series_statements_url
      return
    end

    respond_to do |format|
      if @series_statement.update_attributes(params[:series_statement])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.series_statement'))
        format.html { redirect_to(@series_statement) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_statements/1
  # DELETE /series_statements/1.json
  def destroy
    @series_statement = SeriesStatement.find(params[:id])
    @series_statement.destroy

    respond_to do |format|
      format.html { redirect_to(series_statements_url) }
      format.json { head :no_content }
    end
  end
end
