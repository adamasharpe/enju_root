class SearchHistoriesController < ApplicationController
  before_filter :access_denied, :except => [:index, :show]
  # index, show以外は外部からは呼び出されないはず
  before_filter :login_required
  require_role 'Librarian'
  #before_filter :get_user
  #before_filter :private_content

  # GET /search_histories
  # GET /search_histories.xml
  def index
    #@search_histories = @user.search_histories.paginate(:page => params[:page], :per_page => @per_page, :order => ['created_at DESC'])
    if params[:mode] == 'not_found'
      @search_histories = SearchHistory.not_found.paginate(:page => params[:page], :per_page => @per_page, :order => ['created_at DESC'])
    else
      @search_histories = SearchHistory.paginate(:page => params[:page], :per_page => @per_page, :order => ['created_at DESC'])
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @search_histories.to_xml }
    end
  end

  # GET /search_histories/1
  # GET /search_histories/1.xml
  def show
    @search_history = SearchHistory.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @search_history.to_xml }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # GET /search_histories/new
  def new
  #  @search_history = SearchHistory.new
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  end

  # GET /search_histories/1;edit
  def edit
  #  @search_history = @user.search_histories.find(params[:id])
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  end

  # POST /search_histories
  # POST /search_histories.xml
  def create
  #  if @user
  #    @search_history = @user.search_histories.new(params[:search_history])
  #  else
  #    @search_history = SearchHistory.new(params[:search_history])
  #  end
  #
  #  respond_to do |format|
  #    if @search_history.save
  #      flash[:notice] = ('SearchHistory was successfully created.')
  #      format.html { redirect_to search_history_url(@search_history) }
  #      format.xml  { head :created, :location => search_history_url(@search_history) }
  #    else
  #      format.html { render :action => "new" }
  #      format.xml  { render :xml => @search_history.errors.to_xml }
  #    end
  #  end
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  end

  # PUT /search_histories/1
  # PUT /search_histories/1.xml
  def update
  #  @search_history = @user.search_histories.find(params[:id])
  #
  #  respond_to do |format|
  #    if @search_history.update_attributes(params[:search_history])
  #      flash[:notice] = ('SearchHistory was successfully updated.')
  #      format.html { redirect_to user_search_history_url(@user, @search_history) }
  #      format.xml  { head :ok }
  #    else
  #      format.html { render :action => "edit" }
  #      format.xml  { render :xml => @search_history.errors.to_xml }
  #    end
  #  end
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  end

  # DELETE /search_histories/1
  # DELETE /search_histories/1.xml
  def destroy
    @search_history = SearchHistory.find(params[:id])
    @search_history.destroy

    respond_to do |format|
      #format.html { redirect_to user_search_histories_url(@user.login) }
      format.html { redirect_to search_histories_url }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
