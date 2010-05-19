# -*- encoding: utf-8 -*-
class SubjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_work, :get_subject_heading_type, :get_classification
  before_filter :prepare_options, :only => :new
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]

  # GET /subjects
  # GET /subjects.xml
  def index
    sort = {:sort_by => 'created_at', :order => 'desc'}
    case params[:sort_by]
    when 'name'
      sort[:sort_by] = 'term'
    end
    sort[:order] = 'asc' if params[:order] == 'asc'

    search = Sunspot.new_search(Subject)
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
      end
    end

    search.build do
      order_by sort[:sort_by], sort[:order]
    end

    unless params[:mode] == 'add'
      work = @work
      classification = @classification
      subject_heading_type = @subject_heading_type
      search.build do
        with(:work_ids).equal_to work.id if work
        with(:classification_ids).equal_to classification.id if classification
        with(:subject_heading_type_ids).equal_to subject_heading_type.id if subject_heading_type
      end
    end

    role = current_user.try(:highest_role) || Role.find(1)
    search.build do
      with(:required_role_id).less_than role.id
    end

    page = params[:page] || 1
    search.query.paginate(page.to_i, Subject.per_page)
    begin
      @subjects = search.execute!.results
    rescue RSolr::RequestError
      @subjects = WillPaginate::Collection.create(1,1,0) do end
    end
    session[:params] = {} unless session[:params]
    session[:params][:subject] = params

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @subjects.to_xml }
      format.rss
      format.atom
    end
  rescue RSolr::RequestError
    flash[:notice] = t('page.error_occured')
    redirect_to subjects_url
    return
  end

  # GET /subjects/1
  # GET /subjects/1.xml
  def show
    if params[:term]
      subject = Subject.first(:conditions => {:term => params[:term]})
      redirected_to subject
      return
    end

    @subject = Subject.find(params[:id])
    search = Sunspot.new_search(Work)
    subject = @subject
    search.build do
      with(:subject_ids).equal_to subject.id if subject
    end
    page = params[:work_page] || 1
    search.query.paginate(page.to_i, Work.per_page)
    begin
      @works = search.execute!.results
    rescue RSolr::RequestError
      @works = WillPaginate::Collection.create(1,1,0) do end
    end
    #@works = @subject.works.paginate(:page => params[:work_page], :total_entries => @subject.work_has_subjects.size)

    if @work
      subjected = @subject.works.find(@work) rescue nil
      if subjected.blank?
        redirect_to new_work_work_has_subject_url(@work, :subject_id => @subject.term)
        return
      end
    end

    canonical_url subject_url(@subject)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @subject.to_xml }
      format.js
    end
  end

  # GET /subjects/new
  def new
    @subject = Subject.new
    @subject.classification_id = @classification.id if @classification
    @subject.subject_heading_type_id = @subject_heading_type.id if @subject_heading_type

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @subject }
    end
  end

  # GET /subjects/1;edit
  def edit
    if @work
      @subject = @work.subjects.find(params[:id])
    else
      @subject = Subject.find(params[:id])
    end
    @subject_types = SubjectType.all
  end

  # POST /subjects
  # POST /subjects.xml
  def create
    if @work
      @subject = @work.subjects.new(params[:subject])
    else
      @subject = Subject.new(params[:subject])
    end
    classification = Classification.first(:conditions => {:id => @subject.classification_id}) if @subject.classification_id.present?
    subject_heading_type = SubjectHeadingType.first(:conditions => {:id => @subject.subject_heading_type_id}) if @subject.subject_heading_type_id.present?

    respond_to do |format|
      if @subject.save
        @subject.classifications << classification if classification
        @subject.subject_heading_types << subject_heading_type if subject_heading_type
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.subject'))
        format.html { redirect_to subject_url(@subject) }
        format.xml  { render :xml => @subject, :status => :created, :location => @subject }
      else
        @classification = classification
        @subject_heading_type = subject_heading_type
        prepare_options
        format.html { render :action => "new" }
        format.xml  { render :xml => @subject.errors.to_xml }
      end
    end
  end

  # PUT /subjects/1
  # PUT /subjects/1.xml
  def update
    if @work
      @subject = @work.subjects.find(params[:id])
    else
      @subject = Subject.find(params[:id])
    end

    respond_to do |format|
      if @subject.update_attributes(params[:subject])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.subject'))
        format.html { redirect_to subject_url(@subject) }
        format.xml  { head :ok }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subject.errors.to_xml }
      end
    end
  end

  # DELETE /subjects/1
  # DELETE /subjects/1.xml
  def destroy
    if @work
      @subject = @work.subjects.find(params[:id])
    else
      @subject = Subject.find(params[:id])
    end
    @subject.destroy

    respond_to do |format|
      format.html { redirect_to subjects_url }
      format.xml  { head :ok }
    end
  end

  private
  def prepare_options
    @subject_types = SubjectType.all
  end
end
