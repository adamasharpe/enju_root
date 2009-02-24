class EventsController < ApplicationController
  before_filter :has_permission?, :except => :index
  before_filter :get_library
  before_filter :get_libraries, :except => [:index, :destroy]
  #before_filter :get_patron, :only => [:index]
  before_filter :prepare_options
  after_filter :csv_convert_charset, :only => :index
  before_filter :store_page, :only => :index

  # GET /events
  # GET /events.xml
  def index
    @count = {}
    if params[:date].present?
      if @library.present?
        @events = @library.events.paginate(:conditions => ['started_at <= ? AND ended_at >= ?', params[:date], params[:date]], :page => params[:page])
      else
        @events = Event.paginate(:all, :conditions => ['started_at <= ? AND ended_at >= ?', params[:date], params[:date]], :page => params[:page])
      end
    elsif params[:tag].present?
      if @library.present?
        query = params[:query] + " library_id: #{@library.id}"
      end
      query = "#{query} tag_list: #{params[:tag]}"
      @events = Event.paginate_by_solr(query, :page => params[:page], :per_page => @per_page)
    elsif params[:query].present?
      if @library.present?
        query = params[:query] + " library_id: #{@library.id}"
      else
        query = params[:query]
      end
      @events = Event.paginate_by_solr(query, :page => params[:page], :per_page => @per_page)
    else
      if @library.present?
        @events = @library.events.paginate(:page => params[:page], :order => ['started_at DESC'])
      else
        @events = Event.paginate(:all, :page => params[:page], :order => ['started_at DESC'])
      end
      @count[:query_result] = @events.size
    end
    @query = query

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
      format.rss  { render :layout => false }
      format.csv
      format.atom
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
     prepare_options
    if params[:date]
      begin
        date = Time.parse(params[:date])
      rescue
        date = Time.zone.now.beginning_of_day
        flash[:notice] = t('page.invalid_date')
      end
    else
      date = Time.zone.now.beginning_of_day
    end
    @event = Event.new(:started_at => date, :ended_at => date)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    prepare_options
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])

    respond_to do |format|
      if @event.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.event'))
        format.html { redirect_to(@event) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        prepare_options
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])

        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.event'))
        format.html { redirect_to(@event) }
        format.xml  { head :ok }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end

  private
  def prepare_options
    @event_categories = EventCategory.find(:all, :order => :position)
  end

end
