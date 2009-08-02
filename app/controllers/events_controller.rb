class EventsController < ApplicationController
  before_filter :has_permission?, :except => :index
  before_filter :get_library, :get_patron
  before_filter :get_libraries, :except => [:index, :destroy]
  #before_filter :get_patron, :only => [:index]
  before_filter :prepare_options
  after_filter :convert_charset, :only => :index
  before_filter :store_page, :only => :index

  # GET /events
  # GET /events.xml
  def index
    @count = {}
    query = params[:query].to_s.strip
    @query = query.dup
    query = query.gsub('　', ' ')
    search = Sunspot.new_search(Event)
    search.query.keywords = query if query.present?

    search.query.add_restriction(:library_id, :equal_to, @library.id) if @library
    if params[:tag].present?
      tag = params[:tag].to_s
      search.query.add_restriction(:tag, :equal_to, tag)
    end
    if params[:date].present?
      date = params[:date].to_s
      search.query.add_restriction(:started_at, :greater_than, Time.zone.parse(date).beginning_of_day)
      search.query.add_restriction(:started_at, :less_than, Time.zone.parse(date).tomorrow.beginning_of_day)
    else
      case params[:mode]
      when 'upcoming'
        search.query.add_restriction(:started_at, :greater_than, Time.zone.now.beginning_of_day)
      when 'past'
        search.query.add_restriction(:started_at, :less_than, Time.zone.now.beginning_of_day)
      end
    end
    search.query.order_by(:started_at, :desc)

    page = params[:page] || 1
    search.query.paginate(page.to_i, Event.per_page)
    begin
      @events = search.execute!.results
    rescue RSolr::RequestError
      @events = WillPaginate::Collection.create(1,1,0) do end
    end
    @count[:query_result] = @events.total_entries

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
      format.rss  { render :layout => false }
      format.csv
      format.atom
      format.ics
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
        date = Time.zone.parse(params[:date])
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
    @event_categories = EventCategory.find(:all)
  end

end
