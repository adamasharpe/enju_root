class PageController < ApplicationController
  before_filter :store_location, :except => [:index, :msie_acceralator, :opensearch]
  before_filter :require_user, :except => [:index, :advanced_search, :about, :message, :add_on, :msie_acceralator, :opensearch]
  before_filter :get_libraries, :only => [:advanced_search]
  before_filter :get_user # 上書き注意
  before_filter :check_librarian, :except => [:index, :advanced_search, :about, :message, :add_on, :msie_acceralator, :opensearch]

  def index
    if logged_in?
      redirect_to user_url(current_user.login)
      return
    end
    @numdocs = Manifestation.cached_numdocs
    # TODO: タグ下限の設定
    @tags = Tag.find(:all, :limit => 50, :order => 'taggings_count DESC')
    @manifestation = Manifestation.pickup rescue nil
    @news_feeds = LibraryGroup.site_config.news_feeds rescue nil
  end

  def msie_acceralator
    render :layout => false
  end

  def opensearch
    render :layout => false
  end

  def patron
    @title = t('page.patron_management')
  end
  
  def advanced_search
    @title = t('page.advanced_search')
  end

  def message
    if logged_in?
      redirect_to inbox_user_messages_url(current_user.login)
    else
      redirect_to new_user_session_url
    end
  end

  def circulation
    @title = t('page.circulation')
  end
  
  def statistics
    @title = t('page.statistics')
  end
  
  def acquisition
    @title = t('page.acquisition')
    #@resource = Resource.new
    #@carrier_types = CarrierType.find(:all, :order => 'position')
    #@languages = Language.find(:all, :order => 'position')
  end

  def management
    @title = t('page.management')
  end
  
  def subject
    @title = t('page.subject')
  end
  
  def configuration
    @title = t('page.configuration')
  end

  def import
    @title = t('page.import')
  end
  
  def export
    @title = t('page.export')
  end
  
  def about
    @title = t('page.about_this_system')
  end

  def add_on
    @title = t('page.add_on')
  end

  def under_construction
    @title = t('page.under_construction')
  end

  def service
  end

  private
  def get_user
    @user = current_user if logged_in?
  end

  def check_librarian
    unless current_user.has_role?('Librarian')
      access_denied
    end
  end
  
end
