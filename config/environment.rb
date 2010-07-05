# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "nokogiri"
  config.gem "marc"
  #config.gem "jasper-rails"
  config.gem "RedCloth"
  config.gem "extractcontent"
  config.gem "isbn-tools", :lib => "isbn/tools"
  config.gem "barby"
  config.gem "state_machine"
  config.gem "will_paginate", :version => ">=2.3.14"
  #config.gem "jpmobile"
  config.gem "prawn"
  config.gem "prawn-security", :lib => "prawn/security"
  config.gem "friendly_id", :version => ">=3.0.6"
  #config.gem "graticule"
  #config.gem "acts_as_geocodable"
  config.gem "rails-geocoder", :lib => "geocoder"
  config.gem "calendar_date_select"
  config.gem "scribd_fu"
  config.gem "cancan"
  #config.gem "easy_roles"
  config.gem "strongbox"
  #config.gem "system_timer"
  #config.gem "johnsbrn-has_many_polymorphs", :lib => "has_many_polymorphs"
  config.gem "warden"
  config.gem "warden_oauth"
  config.gem "devise", :version => "1.0.8"
  config.gem "money"
  config.gem "whenever", :lib => false
  #config.gem "rufus-scheduler", :lib => "rufus/scheduler"
  config.gem "acts-as-taggable-on", :version => ">=2.0.6"
  config.gem "memcache-client", :lib => "memcache"
  #config.gem "shared-mime-info"
  config.gem "delayed_job", :version => ">=2.0.2"
  #config.gem "ratom", :lib => "atom"
  #config.gem "damog-feedbag", :lib => "feedbag"
  config.gem "canonical-url", :lib => "canonical_url"
  #config.gem "nabeta-wcapi", :lib => "wcapi"
  #config.gem "sishen-rtranslate", :lib => "rtranslate"
  config.gem "sitemap_generator", :lib => false
  config.gem "paperclip"
  config.gem "sunspot", :version => ">=1.1.0"
  config.gem "sunspot_rails", :lib => "sunspot/rails", :version => ">=1.1.0"
  #config.gem "factory_girl"
  config.gem "ri_cal"
  #config.gem "flickraw"
  config.gem "fastercsv"
  config.gem "Text", :lib => "text"
  config.gem "paper_trail"
  config.gem "file_wrapper"
  config.gem "smurf"
  config.gem "formtastic"
  config.gem "validation_reflection"
  config.gem "recurrence"
  config.gem "prism"
  config.gem "exception_notification"
  config.gem "attribute_normalizer"
  config.gem "rack-openid", :lib => "rack/openid"
  config.gem "erubis"
  config.gem "inherited_resources", :version => "1.0.6"
  config.gem "configatron"
  config.gem "bcrypt-ruby", :lib => "bcrypt"
  #config.gem "twitter"
  #config.gem "twitter-jruby", :lib => "twitter"
  #config.gem "acts_as_archive"
  #config.gem "event_calendar"
  #config.gem "sru"
  #config.gem "cql-ruby", :lib => "cql_ruby"
  #config.gem "newrelic_rpm"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  #config.time_zone = 'UTC'
  config.time_zone = 'Tokyo'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  #config.i18n.default_locale = :de
  config.i18n.default_locale = :ja
end

#RAILS_DEFAULT_LOGGER.auto_flushing = 1

#require 'jasper-rails'
require 'jcode'
require 'nkf'
require 'ipaddr'
require 'digest/sha1'
require 'suggest_tag'
#require 'atom/pub'
require 'bookmark_url'
require 'localized_name'
