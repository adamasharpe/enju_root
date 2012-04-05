# Be sure to restart your server when you modify this file.

#EnjuRoot::Application.config.session_store :cookie_store, :key => '_enju_root_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# EnjuRoot::Application.config.session_store :active_record_store

require 'action_dispatch/middleware/session/dalli_store'
EnjuRoot::Application.config.session_store :dalli_store, :key => '_enju_root_session', :namespace => 'enju_root_session'
