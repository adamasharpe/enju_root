class FrequencyOfIssuesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  require_role 'Administrator', :except => [:index, :show]

  # GET /frequency_of_issues
  # GET /frequency_of_issues.xml
  def index
    @frequency_of_issues = FrequencyOfIssue.find(:all, :order => :position)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @frequency_of_issues }
    end
  end

  # GET /frequency_of_issues/1
  # GET /frequency_of_issues/1.xml
  def show
    @frequency_of_issue = FrequencyOfIssue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @frequency_of_issue }
    end
  end

  # GET /frequency_of_issues/new
  # GET /frequency_of_issues/new.xml
  def new
    @frequency_of_issue = FrequencyOfIssue.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @frequency_of_issue }
    end
  end

  # GET /frequency_of_issues/1/edit
  def edit
    @frequency_of_issue = FrequencyOfIssue.find(params[:id])
  end

  # POST /frequency_of_issues
  # POST /frequency_of_issues.xml
  def create
    @frequency_of_issue = FrequencyOfIssue.new(params[:frequency_of_issue])

    respond_to do |format|
      if @frequency_of_issue.save
        flash[:notice] = ('FrequencyOfIssue was successfully created.')
        format.html { redirect_to(@frequency_of_issue) }
        format.xml  { render :xml => @frequency_of_issue, :status => :created, :location => @frequency_of_issue }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @frequency_of_issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /frequency_of_issues/1
  # PUT /frequency_of_issues/1.xml
  def update
    @frequency_of_issue = FrequencyOfIssue.find(params[:id])

    if @frequency_of_issue and params[:position]
      @frequency_of_issue.insert_at(params[:position])
      redirect_to frequency_of_issues_url
      return
    end

    respond_to do |format|
      if @frequency_of_issue.update_attributes(params[:frequency_of_issue])
        flash[:notice] = ('FrequencyOfIssue was successfully updated.')
        format.html { redirect_to(@frequency_of_issue) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @frequency_of_issue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /frequency_of_issues/1
  # DELETE /frequency_of_issues/1.xml
  def destroy
    @frequency_of_issue = FrequencyOfIssue.find(params[:id])
    @frequency_of_issue.destroy

    respond_to do |format|
      format.html { redirect_to(frequency_of_issues_url) }
      format.xml  { head :ok }
    end
  end
end
