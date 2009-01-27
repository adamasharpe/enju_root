class CheckoutsController < ApplicationController
  before_filter :access_denied, :only => [:new, :create]
  before_filter :login_required, :except => :index
  before_filter :get_user_if_nil, :only => :index
  before_filter :get_user, :except => :index
  #before_filter :private_content, :except => :index
  before_filter :authorized_content, :except => :index
  before_filter :get_item
  after_filter :csv_convert_charset, :only => :index
  
  # GET /checkouts
  # GET /checkouts.xml

  def index
    @library_group = LibraryGroup.find(:first)

    if params[:icalendar_token]
      icalendar_user = User.find(:first, :conditions => {:checkout_icalendar_token => params[:icalendar_token]})
      if icalendar_user.blank?
        raise ActiveRecord::RecordNotFound
      else
        @checkouts = icalendar_user.checkouts.not_returned.find(:all, :order => 'created_at DESC')
      end
    elsif logged_in?
      if current_user.has_role?('Librarian')
        if @user
          @checkouts = @user.checkouts.not_returned.find(:all, :order => 'created_at DESC')
        else
          if params[:view] == 'overdue'
            if params[:days_overdue]
              date = params[:days_overdue].to_i.days.ago.beginning_of_day
            else
              date = 1.days.ago.beginning_of_day
            end
            @checkouts = Checkout.overdue(date).find(:all, :order => 'created_at DESC')
          else
            @checkouts = Checkout.not_returned.find(:all, :order => 'created_at DESC')
          end
        end
      else
        # 一般ユーザ
        if current_user == @user
          @checkouts = current_user.checkouts.not_returned.find(:all, :order => 'created_at DESC')
        else
          access_denied
          return
        end
      end
    else
      access_denied
      return
    end

     @startrecord = (params[:page].to_i - 1) * Checkout.per_page + 1
     if @startrecord < 1
       @startrecord = 1
     end

     @days_overdue = params[:days_overdue] ||= 1

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @checkouts.to_xml }
      format.rss  { render :layout => false }
      format.ics  { render :layout => false }
      format.csv
      format.atom
    end

  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # GET /checkouts/1
  # GET /checkouts/1.xml
  def show
    @checkout = @user.checkouts.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @checkout.to_xml }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # GET /checkouts/new
  def new
  #  @checkout = @user.checkouts.new
  end

  # GET /checkouts/1;edit
  def edit
    @checkout = @user.checkouts.find(params[:id])
    @renew_due_date = @checkout.set_renew_due_date(@user)

  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # POST /checkouts
  # POST /checkouts.xml
  def create
  #  @checkout = @user.checkouts.new(params[:checkout])
  #
  #  respond_to do |format|
  #    if @checkout.id
  #      flash[:notice] = ('Checkout was successfully created.')
  #      format.html { redirect_to user_checkouts_url(@user) }
  #      format.xml  { head :created, :location => checkout_url(@checkout) }
  #    else
  #      #format.html { render :action => "new" }
  #      format.html { redirect_to user_checkouts_url(@user) }
  #      format.xml  { render :xml => @checkout.errors.to_xml }
  #    end
  #  end
  #rescue ActiveRecord::RecordNotFound
  #  not_found
  end

  # PUT /checkouts/1
  # PUT /checkouts/1.xml
  def update
    @checkout = @user.checkouts.find(params[:id])
    if @checkout.reserved?
      flash[:notice] = ('This item is reserved.')
      redirect_to edit_user_checkout_url(@checkout.user.login, @checkout)
      return
    end
    if @checkout.over_checkout_renewal_limit?
      flash[:notice] = ('Excessed checkout renewal limit.')
      redirect_to edit_user_checkout_url(@checkout.user.login, @checkout)
      return
    end
    if @checkout.overdue?
      flash[:notice] = ('You have overdue items.')
      redirect_to edit_user_checkout_url(@checkout.user.login, @checkout)
      return
    end
    # もう一度取得しないとvalidationが有効にならない？
    #@checkout = @user.checkouts.find(params[:id])
    @checkout.reload
    @checkout.checkout_renewal_count += 1

    respond_to do |format|
      if @checkout.update_attributes(params[:checkout])
        flash[:notice] = ('Checkout was successfully updated.')
        format.html { redirect_to user_checkout_url(@checkout.user.login, @checkout) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @checkout.errors.to_xml }
      end
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # DELETE /checkouts/1
  # DELETE /checkouts/1.xml
  def destroy
    @checkout = @user.checkouts.find(params[:id])
    @checkout.destroy

    respond_to do |format|
      format.html { redirect_to user_checkouts_url(@checkout.user.login) }
      format.xml  { head :ok }
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

end
