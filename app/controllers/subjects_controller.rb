class SubjectsController < ApplicationController
  before_filter :has_permission?
  before_filter :get_work
  before_filter :get_classification
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]

  # GET /subjects
  # GET /subjects.xml
  def index
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      unless params[:mode] == 'add'
        query.add_query!(@work) if @work
        query.add_query!(@classification) if @classification
        query.add_query!(@subject_heading_type) if @subject_heading_type
      end
      @subjects = Subject.paginate_by_solr(query, :page => params[:page]).compact
    else
      case
      when @work
        if params[:mode] == 'add'
          @subjects = Subject.paginate(:page => params[:page], :order => 'subjects.id DESC')
        else
          @subjects = @work.subjects.paginate(:page => params[:page], :order => 'subjects.id', :total_entries => @work.resource_has_subjects.size)
        end
      when @classification
        @subjects = @classification.subjects.paginate(:page => params[:page], :order => 'subjects.id')
      when @subject_heading_type
        @subjects = @subject_heading_type.subjects.paginate(:page => params[:page], :order => 'subjects.id')
      else
        @subjects = Subject.paginate(:all, :page => params[:page], :order => 'subjects.id')
      end
    end
    session[:params] = {} unless session[:params]
    session[:params][:subject] = params

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @subjects.to_xml }
    end
  end

  # GET /subjects/1
  # GET /subjects/1.xml
  def show
    if params[:term]
      subject = Subject.find(:first, :conditions => {:term => params[:term]})
      redirected_to subject
      return
    end

    @subject = Subject.find(params[:id])
    @works = @subject.works.paginate(:page => params[:work_page], :total_entries => @subject.resource_has_subjects.size)

    if @work
      subjected = @subject.works.find(@work) rescue nil
      if subjected.blank?
        redirect_to new_work_resource_has_subject_url(@work, :subject_id => @subject.term)
        return
      end
    end

    canonical_url subject_url(@subject)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @subject.to_xml }
      format.js {
        render :update do |page|
          page.replace_html 'work_list', :partial => 'show_work_list' if params[:work_page]
        end
      }
    end
  end

  # GET /subjects/new
  def new
    @subject = Subject.new
    @subject_types = SubjectType.find(:all)

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
    @subject_types = SubjectType.find(:all)
  end

  # POST /subjects
  # POST /subjects.xml
  def create
    if @work
      @subject = @work.subjects.new(params[:subject])
    else
      @subject = Subject.new(params[:subject])
    end

    respond_to do |format|
      if @subject.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.subject'))
        format.html { redirect_to subject_url(@subject) }
        format.xml  { render :xml => @subject, :status => :created, :location => @subject }
      else
        @subject_types = SubjectType.find(:all)
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
        @subject_types = SubjectType.find(:all)
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

end
