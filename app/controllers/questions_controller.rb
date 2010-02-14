# -*- encoding: utf-8 -*-
class QuestionsController < ApplicationController
  before_filter :has_permission?
  before_filter :get_user_if_nil, :except => [:edit]
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  include PortaController

  # GET /questions
  # GET /questions.xml
  def index
    store_location
    session[:params] = {} unless session[:params]
    session[:params][:question] = params

    @count = {}

    search = Sunspot.new_search(Question)
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
        order_by(:updated_at, :desc)
      end
    end

    if @user
      if logged_in?
        user = @user
        c_user = current_user
        search.build do
          with(:login).equal_to user.login unless user.has_role?('Librarian')
        end
      end
    end
    page = params[:page] || 1
    search.query.paginate(page.to_i, Question.per_page)
    begin
      @questions = search.execute!.results
    rescue RSolr::RequestError
      @questions = WillPaginate::Collection.create(1,1,0) do end
    end
    @count[:query_result] = @questions.total_entries

    if query
      @crd_results = search_porta_crd(query, :page => params[:crd_page])
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @questions.to_xml }
      format.rss  { render :layout => false }
      format.atom
      format.js {
        render :update do |page|
          page.replace_html 'result_index', :partial => 'list' if params[:page]
          page.replace_html 'submenu', :partial => 'crd' if params[:crd_page]
        end
      }
    end
  rescue RSolr::RequestError
    flash[:notice] = t('page.error_occured')
    redirect_to questions_url
    return
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end

    respond_to do |format|
      format.html # show.rhtml
      format.xml  {
        if params[:mode] == 'crd'
          render :template => 'questions/show_crd'
          convert_charset
        else
          render :xml => @question.to_xml
        end
      }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # GET /questions/new
  def new
    @question = current_user.questions.new
  end

  # GET /questions/1;edit
  def edit
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = current_user.questions.new(params[:question])

    respond_to do |format|
      if @question.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.question'))
        format.html { redirect_to user_question_url(@question.user.login, @question) }
        format.xml  { render :xml => @question, :status => :created, :location => user_question_url(@question.user.login, @question) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors.to_xml }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    @question = @user.questions.find(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:question])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.question'))
        format.html { redirect_to user_question_url(@question.user.login, @question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors.to_xml }
      end
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    if @user
      @question = @user.questions.find(params[:id])
    else
      @question = Question.find(params[:id])
    end
    @question.destroy

    respond_to do |format|
      format.html { redirect_to user_questions_url(@question.user.login) }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

end
