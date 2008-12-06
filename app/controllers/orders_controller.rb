class OrdersController < ApplicationController
  before_filter :check_client_ip_address
  before_filter :login_required
  require_role 'Librarian'
  before_filter :get_order_list
  before_filter :get_purchase_request

  # GET /orders
  # GET /orders.xml
  def index
    case
    when @order_list
      @orders = @order_list.orders.paginate(:page => params[:page], :per_page => @per_page)
    else
      @orders = Order.paginate(:all, :page => params[:page], :per_page => @per_page)
    end
    @count = {}
    @count[:query_result] = @orders.size
    @startrecord = (params[:page].to_i - 1) * Order.per_page + 1
    if @startrecord < 1
      @startrecord = 1
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @orders }
      format.rss  { render :layout => false }
      format.csv
    end
  end

  # GET /orders/1
  # GET /orders/1.xml
  def show
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.xml
  def new
    unless @purchase_request
      flash[:notice] = ('You should specify purchase request id.')
      redirect_to purchase_requests_url
      return
    end
    @order = Order.new(params[:order])
    @order_lists = OrderList.not_ordered

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
    @order_lists = OrderList.not_ordered
  end

  # POST /orders
  # POST /orders.xml
  def create
    @order = Order.new(params[:order])

    respond_to do |format|
      if @order.save
        flash[:notice] = ('Order was successfully created.')
        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.xml  { render :xml => @order, :status => :created, :location => @order }
        else
          format.html { redirect_to(@order) }
          format.xml  { render :xml => @order, :status => :created, :location => @order }
        end
      else
        @order_lists = OrderList.not_ordered
        format.html { render :action => "new" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.xml
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        flash[:notice] = ('Order was successfully updated.')
        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.xml  { head :ok }
        else
          format.html { redirect_to(@order) }
          format.xml  { head :ok }
        end
      else
        @order_lists = OrderList.not_ordered
        format.html { render :action => "edit" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.xml
  def destroy
    @order = Order.find(params[:id])

    @order.destroy

    respond_to do |format|
      if @order_list
        format.html { redirect_to order_list_purchase_requests_url(@order_list) }
        format.xml  { head :ok }
      else
        format.html { redirect_to(orders_url) }
        format.xml  { head :ok }
      end
    end
  end
end
