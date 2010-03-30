# -*- encoding: utf-8 -*-
class ReservesController < ApplicationController
  before_filter :has_permission?
  before_filter :get_user_if_nil
  #, :only => [:show, :edit, :create, :update, :destroy]
  before_filter :get_manifestation, :only => [:new]
  before_filter :get_item, :only => [:new]
  before_filter :store_page, :only => :index

  # GET /reserves
  # GET /reserves.xml
  def index
    if logged_in?
      begin
        if !current_user.has_role?('Librarian')
          raise unless current_user == @user
        end
      rescue
        if @user
          unless current_user == @user
            access_denied; return
          end
        else
          redirect_to user_reserves_path(current_user.login)
          return
        end
      end
    end

    if params[:mode] == 'hold' and current_user.has_role?('Librarian')
      @reserves = Reserve.hold.paginate(:page => params[:page], :order => ['reserves.created_at DESC'])
    else
      if @user
        # 一般ユーザ
        @reserves = @user.reserves.paginate(:page => params[:page], :order => ['reserves.expired_at DESC'])
      else
        # 管理者
        @reserves = Reserve.paginate(:all, :page => params[:page], :order => ['reserves.expired_at DESC'], :include => :manifestation)
      end
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @reserves.to_xml }
      format.rss  { render :layout => false }
      format.atom
    end
  end

  # GET /reserves/1
  # GET /reserves/1.xml
  def show
    if @user
      @reserve = @user.reserves.find(params[:id])
    else
      if current_user.has_role?('Librarian')
        @reserve = Reserve.find(params[:id]) if current_user.has_role?('Librarian')
      else
        access_denied
        return
      end
    end
    #@manifestation = @reserve.manifestation

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @reserve.to_xml }
    end
  end

  # GET /reserves/new
  def new
    get_user_if_nil
    user = get_user_number ||= @user
    unless current_user.has_role?('Librarian')
      if user.try(:user_number).blank?
        access_denied; return
      end
    end

    unless current_user.has_role?('Librarian')
      if user.blank? or user != current_user
        access_denied
        return
      end
    end

    if user
      @reserve = user.reserves.new
    else
      @reserve = Reserve.new
    end

    if @manifestation
      @reserve.manifestation = @manifestation
      if user
        @reserve.expired_at = @manifestation.reservation_expired_period(user).days.from_now.end_of_day
        if @manifestation.is_reserved_by(user)
          flash[:notice] = t('reserve.this_manifestation_is_already_reserved')
          redirect_to @manifestation
          return
        end
      end
    end
  end

  # GET /reserves/1;edit
  def edit
    if @user
      @reserve = @user.reserves.find(params[:id])
    else
      @reserve = Reserve.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  # POST /reserves
  # POST /reserves.xml
  def create
    user = get_user_number
    # 図書館員以外は自分の予約しか作成できない
    unless current_user.has_role?('Librarian')
      unless user == current_user
        access_denied
        return
      end
    end

    @reserve = Reserve.new(params[:reserve])
    @reserve.user = user

    @manifestation = Manifestation.find(params[:reserve][:manifestation_id]) rescue nil

    if @reserve.user and @manifestation
      begin
        if @manifestation.is_reserved_by(@reserve.user)
          flash[:notice] = t('reserve.this_manifestation_is_already_reserved')
          raise
        end
        if @reserve.user.reached_reservation_limit?(@manifestation)
          flash[:notice] = t('reserve.excessed_reservation_limit')
          raise
        end
        expired_period = @manifestation.reservation_expired_period(@reserve.user)
        if expired_period.nil?
          flash[:notice] = t('reserve.this_patron_cannot_reserve')
          raise
        end

        @reserve.manifestation = @manifestation
      rescue
        flash[:notice] = t('page.error_occured') if flash[:notice].nil?
        redirect_to @manifestation
        return
      end
    end

    respond_to do |format|
      if @reserve.save
        # 予約受付のメール送信
        #unless user.email.blank?
        #  ReservationNotifier.deliver_accepted(user, @reserve.manifestation)
        #end
        @reserve.send_message('accepted')

        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.reserve'))
        #format.html { redirect_to reserve_url(@reserve) }
        format.html { redirect_to user_reserve_url(@reserve.user.login, @reserve) }
        format.xml  { render :xml => @reserve, :status => :created, :location => user_reserve_url(@reserve.user.login, @reserve) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @reserve.errors.to_xml }
      end
    end
  end

  # PUT /reserves/1
  # PUT /reserves/1.xml
  def update
    @user = get_user_number
    if @user.blank?
      get_user_if_nil
    end

    if @user.blank?
      access_denied
      return
    end

    if @user
      @reserve = @user.reserves.find(params[:id])
    else
      @reserve = Reserve.find(params[:id])
    end

    if params[:mode] == 'cancel'
      @reserve.aasm_cancel!
    end

    respond_to do |format|
      if @reserve.update_attributes(params[:reserve])
        if @reserve.state == 'canceled'
          flash[:notice] = t('reserve.reservation_was_canceled')
          @reserve.send_message('canceled')
        else
          flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.reserve'))
        end
        format.html { redirect_to user_reserve_url(@user.login, @reserve) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reserve.errors.to_xml }
      end
    end
  end

  # DELETE /reserves/1
  # DELETE /reserves/1.xml
  def destroy
    if @user
      @reserve = @user.reserves.find(params[:id])
    else
      @reserve = Reserve.find(params[:id])
    end
    @reserve.destroy
    #flash[:notice] = t('reserve.reservation_was_canceled')

    if @reserve.manifestation.is_reserved_by
      if @reserve.item
        retain = @reserve.item.retain(User.find(1)) # TODO: システムからの送信ユーザの設定
        if retain.nil?
          flash[:message] = t('reserve.this_item_is_not_reserved')
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to user_reserves_url(@user.login) }
      format.xml  { head :ok }
    end
  end

  private
  def get_user_number
    if params[:reserve][:user_number]
      user = User.first(:conditions => {:user_number => params[:reserve][:user_number]})
    #elsif params[:reserve][:user_id]
    #  user = User.first(:conditions => {:id => params[:reserve][:user_id]})
    end
  rescue
    nil
  end
end
