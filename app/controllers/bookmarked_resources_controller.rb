class BookmarkedResourcesController < ApplicationController
  before_filter :access_denied, :only => [:new, :create]
  before_filter :has_permission?
  before_filter :get_user_if_nil
  #before_filter :get_manifestation, :only => [:new]
  before_filter :store_location, :except => [:create, :update, :destroy]
  after_filter :convert_charset, :only => :index
  cache_sweeper :resource_sweeper, :only => [:create, :update, :destroy]
  helper :bookmarks

  # GET /bookmarked_resources
  # GET /bookmarked_resources.xml
  def index
    if logged_in?
      if !current_user.has_role?('Librarian') and @user
        if !@user.share_bookmarks? and current_user != @user
          access_denied; return
        end
      end
    end

    session[:bookmarked_resource_ids] = [] unless session[:bookmarked_resource_ids]
    session[:params] = {} unless session[:params]
    session[:params][:manifestation] = nil

    search = Sunspot.new_search(Manifestation)
    @count = {}
    query = params[:query]
    #query = make_query(params[:query], {:tag => params[:tag]})
    unless query.blank?
      @query = query.dup
      search.query.keywords = query
    end
    if @user
      search.query.add_restriction(:user, :equal_to, @user.login)
    else
      if logged_in?
        unless current_user.has_role?('Librarian')
          redirect_to user_bookmarks_url(current_user.login)
          return
        end
      else
        access_denied
        return
      end
    end
    page = params[:page] || 1
    search.query.paginate(page.to_i, BookmarkedResource.per_page)
    @bookmarked_resources = search.execute!.results

    bookmarked_resource_ids = Manifestation.search_ids do
      keywords query
      order_by :updated_at, :desc
      paginate :page => 1, :per_page => Manifestation.per_page
    end
    @count[:query_result] = @bookmarked_resources.total_entries
    session[:bookmarked_resource_ids] = bookmarked_resource_ids
    #rescue
    #  @bookmarked_resources = []
    #  @count[:query_result] = 0
    #end
    #raise query

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @bookmarked_resources }
      format.rss  { render :layout => false }
      format.csv
    end
  rescue RSolr::RequestError
    redirect_to user_bookmarked_resources_url(current_user.login)
    return
  end

  # GET /bookmarked_resources/1
  # GET /bookmarked_resources/1.xml
  def show
    @bookmarked_resource = BookmarkedResource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bookmarked_resource }
    end
  end

  # GET /bookmarked_resources/new
  # GET /bookmarked_resources/new.xml
  def new
    @bookmarked_resource = BookmarkedResource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bookmarked_resource }
    end
  end

  # GET /bookmarked_resources/1/edit
  def edit
    @bookmarked_resource = BookmarkedResource.find(params[:id])
  end

  # POST /bookmarked_resources
  # POST /bookmarked_resources.xml
  def create
    @bookmarked_resource = BookmarkedResource.new(params[:bookmarked_resource])

    respond_to do |format|
      if @bookmarked_resource.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.bookmarked_resource'))
        if @user
          format.html { redirect_to(user_bookmarked_resource_url(@user.login, @bookmarked_resource)) }
          format.xml  { render :xml => @bookmarked_resource, :status => :created, :location => @bookmarked_resource }
        else
          format.html { redirect_to(@bookmarked_resource) }
          format.xml  { render :xml => @bookmarked_resource, :status => :created, :location => @bookmarked_resource }
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bookmarked_resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bookmarked_resources/1
  # PUT /bookmarked_resources/1.xml
  def update
    @bookmarked_resource = BookmarkedResource.find(params[:id])
    unless params[:bookmarked_resource][:title]
      url = URI.parse(params[:bookmarked_resource][:url]).normalize.to_s
      #params[:bookmarked_resource][:title] = Bookmark.get_title(URI.encode(url), root_url) if url
    end

    respond_to do |format|
      if @bookmarked_resource.update_attributes(params[:bookmarked_resource])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.bookmarked_resource'))
        if @user
          format.html { redirect_to(user_bookmarked_resource_url(@user.login, @bookmarked_resource)) }
          format.xml  { head :ok }
        else
          format.html { redirect_to(@bookmarked_resource) }
          format.xml  { head :ok }
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bookmarked_resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarked_resources/1
  # DELETE /bookmarked_resources/1.xml
  def destroy
    @bookmarked_resource = BookmarkedResource.find(params[:id])
    @bookmarked_resource.destroy

    respond_to do |format|
      if @user
        format.html { redirect_to(user_bookmarked_resources_url(@user.login)) }
        format.xml  { head :ok }
      else
        format.html { redirect_to(bookmarked_resources_url) }
        format.xml  { head :ok }
      end
    end
  end

  private
  def share_bookmarks?
    if @user
      @user.share_bookmarks?
    end
  end

  def make_query(query, options = {})
    query = query.to_s.strip

    if options[:mode] == 'recent'
      # クエリ上書き
      query = "created_at: [#{1.month.ago.utc.iso8601} TO *]"
    end

    unless options[:tag].blank?
      query = "#{query} tag: #{options[:tag]}"
    end

    query = query.strip
    if query == '[* TO *]'
      query = ''
    end
    return query
  end

end
