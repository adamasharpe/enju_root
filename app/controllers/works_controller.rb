# -*- encoding: utf-8 -*-
class WorksController < ApplicationController
  before_filter :has_permission?
  before_filter :get_patron, :get_subject, :get_subscription
  before_filter :get_work, :only => :index
  before_filter :get_series_statement, :only => [:index, :new, :edit]
  before_filter :get_work_merge_list
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :get_version, :only => [:show]
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  # GET /works
  # GET /works.xml
  def index
    query = params[:query].to_s.strip
    search = Sunspot.new_search(Work)
    @count = {}
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
      end
    end

    set_role_query(current_user, search)

    unless params[:mode] == 'add'
      patron = @patron
      subject = @subject
      subscription = @subscription
      work = @work
      work_merge_list = @work_merge_list
      search.build do
        with(:patron_ids).equal_to patron.id if patron
        with(:subject_ids).equal_to subject.id if subject
        with(:subscription_ids).equal_to subscription.id if subscription
        with(:original_work_ids).equal_to work.id if work
        with(:work_merge_list_ids).equal_to work_merge_list.id if work_merge_list
      end
    end

    role = current_user.try(:highest_role) || Role.find(1)
    search.build do
      with(:required_role_id).less_than role.id
    end

    page = params[:page] || 1
    search.query.paginate(page.to_i, Work.per_page)
    begin
      @works = search.execute!.results
    rescue RSolr::RequestError
      @works = WillPaginate::Collection.create(1,1,0) do end
    end
    @count[:total] = @works.total_entries

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @works }
      format.atom
    end
  rescue RSolr::RequestError
    flash[:notice] = t('page.error_occured')
    redirect_to works_url
    return
  end

  # GET /works/1
  # GET /works/1.xml
  def show
    @work = Work.find(params[:id])
    @work = @work.versions.find(@version).item if @version

    if @patron
      created = @work.patrons.find(@patron) rescue nil
      if created.blank?
        redirect_to :controller => 'creates', :action => 'new', :work_id => @work.id, :patron_id => @patron.id
        return
      end
    end
    search = Sunspot.new_search(Subject)
    work = @work.dup
    search.build do
      with(:work_ids).equal_to work.id if work
    end
    page = params[:subject_page] || 1
    search.query.paginate(page.to_i, Subject.per_page)
    begin
      @subjects = search.execute!.results
    rescue RSolr::RequestError
      @subjects = WillPaginate::Collection.create(1,1,0) do end
    end

    #@subjects = @work.subjects.paginate(:page => params[:subject_page], :total_entries => @work.work_has_subjects.size)

    canonical_url work_url(@work)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @work }
      format.json { render :json => @work }
      format.js {
        render :update do |page|
          page.replace_html 'subject_list', :partial => 'show_subject_list' if params[:subject_page]
        end
      }
    end
  end

  # GET /works/new
  def new
    @work = Work.new
    @patron = Patron.find(params[:patron_id]) rescue nil
    if @series_statement
      @work.series_statement = @series_statement
      @work.original_title = @series_statement.original_title
      @work.title_transcription = @series_statement.title_transcription
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @work }
    end
  end

  # GET /works/1;edit
  def edit
    @work = Work.find(params[:id])
    @work.series_statement = @series_statement
  end

  # POST /works
  # POST /works.xml
  def create
    @work = Work.new(params[:work])

    respond_to do |format|
      if @work.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.work'))
        if @patron
          @patron.works << @work
        end
        format.html { redirect_to @work }
        format.xml  { render :xml => @work, :status => :created, :location => @work }
      else
        prepare_options
        format.html { render :action => "new" }
        format.xml  { render :xml => @work.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /works/1
  # PUT /works/1.xml
  def update
    @work = Work.find(params[:id])

    respond_to do |format|
      if @work.update_attributes(params[:work])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.work'))
        format.html { redirect_to work_url(@work) }
        format.xml  { head :ok }
        format.json { render :json => @work }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.xml  { render :xml => @work.errors, :status => :unprocessable_entity }
        format.json { render :json => @work, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /works/1
  # DELETE /works/1.xml
  def destroy
    @work = Work.find(params[:id])
    @work.destroy

    respond_to do |format|
      flash[:notice] = t('controller.successfully_deleted', :model => t('activerecord.models.work'))
      format.html { redirect_to works_url }
      format.xml  { head :ok }
    end
  end

  private
  def prepare_options
    @form_of_works = FormOfWork.all
    @roles = Role.all
  end

end
