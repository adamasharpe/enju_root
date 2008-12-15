class ManifestationCheckoutStatsController < ApplicationController
  before_filter :login_required, :except => ['index', 'show']
  require_role 'Librarian', :except => ['index', 'show']

  # GET /manifestation_checkout_stats
  # GET /manifestation_checkout_stats.xml
  def index
    @manifestation_checkout_stats = ManifestationCheckoutStat.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @manifestation_checkout_stats }
    end
  end

  # GET /manifestation_checkout_stats/1
  # GET /manifestation_checkout_stats/1.xml
  def show
    @manifestation_checkout_stat = ManifestationCheckoutStat.find(params[:id])
    @stats = @manifestation_checkout_stat.manifestation_checkout_stat_has_manifestations.paginate(:all, :order => 'checkouts_count DESC, manifestation_id', :page => params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @manifestation_checkout_stat }
    end
  end

  # GET /manifestation_checkout_stats/new
  # GET /manifestation_checkout_stats/new.xml
  def new
    @manifestation_checkout_stat = ManifestationCheckoutStat.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @manifestation_checkout_stat }
    end
  end

  # GET /manifestation_checkout_stats/1/edit
  def edit
    @manifestation_checkout_stat = ManifestationCheckoutStat.find(params[:id])
  end

  # POST /manifestation_checkout_stats
  # POST /manifestation_checkout_stats.xml
  def create
    @manifestation_checkout_stat = ManifestationCheckoutStat.new(params[:manifestation_checkout_stat])

    respond_to do |format|
      if @manifestation_checkout_stat.save
        flash[:notice] = 'ManifestationCheckoutStat was successfully created.'
        format.html { redirect_to(@manifestation_checkout_stat) }
        format.xml  { render :xml => @manifestation_checkout_stat, :status => :created, :location => @manifestation_checkout_stat }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @manifestation_checkout_stat.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /manifestation_checkout_stats/1
  # PUT /manifestation_checkout_stats/1.xml
  def update
    @manifestation_checkout_stat = ManifestationCheckoutStat.find(params[:id])

    respond_to do |format|
      if @manifestation_checkout_stat.update_attributes(params[:manifestation_checkout_stat])
        flash[:notice] = 'ManifestationCheckoutStat was successfully updated.'
        format.html { redirect_to(@manifestation_checkout_stat) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @manifestation_checkout_stat.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /manifestation_checkout_stats/1
  # DELETE /manifestation_checkout_stats/1.xml
  def destroy
    @manifestation_checkout_stat = ManifestationCheckoutStat.find(params[:id])
    @manifestation_checkout_stat.destroy

    respond_to do |format|
      format.html { redirect_to(manifestation_checkout_stats_url) }
      format.xml  { head :ok }
    end
  end
end
