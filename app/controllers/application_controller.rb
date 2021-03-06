# -*- encoding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied, :with => :render_403
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  rescue_from Errno::ECONNREFUSED, :with => :render_500
  rescue_from RSolr::Error::Http, :with => :render_500_solr
  rescue_from ActionView::MissingTemplate, :with => :render_404_invalid_format

  before_filter :get_library_group, :set_locale, :set_available_languages

  private
  def after_sign_in_path_for(resource)
    session[:locale] = nil
    super
  end

  def render_403
    return if performed?
    if user_signed_in?
      respond_to do |format|
        format.html {render :template => 'page/403', :status => 403}
        format.xml {render :template => 'page/403', :status => 403}
      end
    else
      respond_to do |format|
        format.html {redirect_to new_user_session_url}
        format.xml {render :template => 'page/403', :status => 403}
      end
    end
  end

  def render_404
    return if performed?
    respond_to do |format|
      format.html {render :template => 'page/404', :status => 404}
      format.xml {render :template => 'page/404', :status => 404}
    end
  end

  def render_404_invalid_format
    return if performed?
    render :file => "#{Rails.root}/public/404.html"
  end

  def render_500
    return if performed?
    #flash[:notice] = t('page.connection_failed')
    respond_to do |format|
      format.html {render :file => "#{Rails.root.to_s}/public/500.html", :layout => false, :status => 500}
      format.mobile {render :file => "#{Rails.root.to_s}/public/500.html", :layout => false, :status => 500}
    end
  end

  def render_500_solr
    return if performed?
    #flash[:notice] = t('page.connection_failed')
    respond_to do |format|
      format.html {render :template => 'page/500', :status => 500}
      format.mobile {render :template => 'page/500', :status => 500}
      format.xml {render :template => 'page/500', :status => 500}
    end
  end

  def get_library_group
    @library_group = LibraryGroup.site_config
  end

  def set_locale
    if params[:locale]
      unless I18n.available_locales.include?(params[:locale].to_s.intern)
        raise InvalidLocaleError
      end
    end
    if user_signed_in?
      locale = params[:locale] || session[:locale] || current_user.locale.try(:to_sym)
    else
      locale = params[:locale] || session[:locale]
    end
    if locale
      I18n.locale = @locale = session[:locale] = locale.to_sym
    else
      I18n.locale = @locale = session[:locale] = I18n.default_locale
    end
  rescue InvalidLocaleError
    @locale = I18n.default_locale
  end

  def default_url_options(options={})
    {:locale => nil}
  end

  def set_available_languages
    if Rails.env == 'production'
      @available_languages = Rails.cache.fetch('available_languages'){
        Language.where(:iso_639_1 => I18n.available_locales.map{|l| l.to_s}).select([:id, :iso_639_1, :name, :native_name, :display_name, :position]).all
      }
    else
      @available_languages = Language.where(:iso_639_1 => I18n.available_locales.map{|l| l.to_s})
    end
  end

  def reset_params_session
    session[:params] = nil
  end

  def not_found
    raise ActiveRecord::RecordNotFound
  end

  def access_denied
    raise CanCan::AccessDenied
  end

  def get_patron
    @patron = Patron.find(params[:patron_id]) if params[:patron_id]
    authorize! :show, @patron if @patron
  end

  def get_work
    @work = Work.find(params[:work_id]) if params[:work_id]
    authorize! :show, @work if @work
  end

  def get_item
    @item = Item.find(params[:item_id]) if params[:item_id]
    authorize! :show, @item if @item
  end

  def get_expression
    @expression = Expression.find(params[:expression_id]) if params[:expression_id]
    authorize! :show, @expression if @expression
  end

  def get_manifestation
    @manifestation = Manifestation.find(params[:manifestation_id]) if params[:manifestation_id]
    authorize! :show, @manifestation if @manifestation
  end

  def get_carrier_type
    @carrier_type = CarrierType.find(params[:carrier_type_id]) if params[:carrier_type_id]
  end

  def get_shelf
    @shelf = Shelf.find(params[:shelf_id], :include => :library) if params[:shelf_id]
  end

  def get_basket
    @basket = Basket.find(params[:basket_id]) if params[:basket_id]
  end

  def get_patron_merge_list
    @patron_merge_list = PatronMergeList.find(params[:patron_merge_list_id]) if params[:patron_merge_list_id]
  end

  def get_work_merge_list
    @work_merge_list = WorkMergeList.find(params[:work_merge_list_id]) if params[:work_merge_list_id]
  end

  def get_expression_merge_list
    @expression_merge_list = ExpressionMergeList.find(params[:expression_merge_list_id]) if params[:expression_merge_list_id]
  end

  def get_user
    @user = User.where(:username => params[:user_id]).first if params[:user_id]
    if @user
      authorize! :show, @user
    else
      raise ActiveRecord::RecordNotFound
    end
    return @user
  end

  def get_user_if_nil
    @user = User.where(:username => params[:user_id]).first if params[:user_id]
    #authorize! :show, @user if @user
  end

  def get_user_group
    @user_group = UserGroup.find(params[:user_group_id]) if params[:user_group_id]
  end
                    
  def get_library
    @library = Library.find(params[:library_id]) if params[:library_id]
  end

  def get_libraries
    @libraries = Library.all
  end

  def get_library_group
    @library_group = LibraryGroup.site_config
  end

  def get_event
    @event = Event.find(params[:event_id]) if params[:event_id]
  end

  def get_subject
    @subject = Subject.find(params[:subject_id]) if params[:subject_id]
  end

  def get_classification
    @classification = Classification.find(params[:classification_id]) if params[:classification_id]
  end

  def get_subject_heading_type
    @subject_heading_type = SubjectHeadingType.find(params[:subject_heading_type_id]) if params[:subject_heading_type_id]
  end

  def get_series_statement
    @series_statement = SeriesStatement.find(params[:series_statement_id]) if params[:series_statement_id]
  end

  def convert_charset
    #if params[:format] == 'ics'
    #  response.body = NKF::nkf('-w -Lw', response.body)
    case params[:format]
    when 'csv'
      return unless Setting.csv_charset_conversion
      # TODO: 他の言語
      if @locale == 'ja'
        headers["Content-Type"] = "text/csv; charset=Shift_JIS"
        response.body = NKF::nkf('-Ws', response.body)
      end
    when 'xml'
      if @locale == 'ja'
        headers["Content-Type"] = "application/xml; charset=Shift_JIS"
        response.body = NKF::nkf('-Ws', response.body)
      end
    end
  end

  def my_networks?
    return true if LibraryGroup.site_config.network_access_allowed?(request.remote_ip, :network_type => 'lan')
    false
  end

  def admin_networks?
    return true if LibraryGroup.site_config.network_access_allowed?(request.remote_ip, :network_type => 'admin')
    false
  end

  def check_client_ip_address
    access_denied unless my_networks?
  end

  def check_admin_network
    access_denied unless admin_networks?
  end

  def store_page
    flash[:page] = params[:page].to_i if params[:page]
  end

  def store_location
    if request.get? and request.format.try(:html?) and !request.xhr?
      session[:user_return_to] = request.fullpath
    end
  end

  def set_role_query(user, search)
    role = user.try(:role) || Role.default_role
    search.build do
      with(:required_role_id).less_than_or_equal_to role.id
    end
  end

  def make_internal_query(search)
    # 内部的なクエリ
    set_role_query(current_user, search)

    unless params[:mode] == "add"
      expression = @expression
      patron = @patron
      manifestation = @manifestation
      carrier_type = params[:carrier_type]
      library = params[:library]
      language = params[:language]
      subject = params[:subject]
      subject_by_term = Subject.where(:term => params[:subject]).first
      @subject_by_term = subject_by_term

      search.build do
        with(:expression_ids).equal_to expression.id if expression
        with(:patron_ids).equal_to patron.id if patron
        with(:original_manifestation_ids).equal_to manifestation.id if manifestation
        unless carrier_type.blank?
          with(:carrier_type).equal_to carrier_type
          with(:carrier_type).equal_to carrier_type
        end
        unless library.blank?
          library_list = library.split.uniq
          library_list.each do |library|
            with(:library).equal_to library
          end
        end
        unless language.blank?
          language_list = language.split.uniq
          language_list.each do |language|
            with(:language).equal_to language
          end
        end
        unless subject.blank?
          with(:subject).equal_to subject_by_term.term
        end
      end
    end
    return search
  end

  def solr_commit
    Sunspot.commit
  end

  def get_version
    @version = params[:version_id].to_i if params[:version_id]
    @version = nil if @version == 0
  end

  def clear_search_sessions
    session[:query] = nil
    session[:params] = nil
    session[:search_params] = nil
    session[:manifestation_ids] = nil
  end

  def api_request?
    true unless params[:format].nil? or params[:format] == 'html'
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, request.remote_ip)
  end

  def get_top_page_content
     @manifestation = Manifestation.pickup rescue nil
  end

  def move_position(resource, direction, redirect = true)
    if ['higher', 'lower'].include?(direction)
      resource.send("move_#{direction}")
      if redirect
        redirect_to url_for(:controller => resource.class.to_s.pluralize.underscore)
        return
      end
    end
  end
end

class InvalidLocaleError < StandardError
end
