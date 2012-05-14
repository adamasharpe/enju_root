class CountriesController < InheritedResources::Base
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def update
    @country = Country.find(params[:id])
    if params[:position]
      @country.insert_at(params[:position])
      redirect_to countries_url
      return
    end
    update!
  end

  def index
    @countries = @countries.paginate(:page => params[:page])
  end

  private
  def interpolation_options
    {:resource_name => t('activerecord.models.country')}
  end
end
