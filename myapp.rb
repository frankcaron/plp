# ==============================
# PLP
# Frank Caron
# Feb 2015
#
# A simple Storefront app for connecting to the Points LCP
# 
# ==============================

# |||| Reqs ||||

require 'sinatra'
require 'csv'

# |||| Default Settings ||||

set :views, Proc.new { File.join(settings.root, "/plp") }
set :public_folder, Proc.new { File.join(root, "plp") }
set :show_exceptions, true
set :static_cache_control, [:public, max_age: 0]

session = false
sessionID = ""

# ------------------------------
# Partner-specific Landing Page
# ------------------------------
# Before any partner-specific visit, set up the views to point to the right partner folder

before '/account/*' do
	# Validate session
	unless session && sessionID != nil
		redirect '/'
	end
end

get '/signup' do
 	erb :signup
end

get '/login' do
 	erb :login
end

get '/profile' do
 	erb :profile
end

get '/give' do
 	erb :give
end

get '/*' do
 	erb :index
end

# ------------------------------
# Helpers
# ------------------------------
# Helper functions

helpers do

  def determine_app_credentials(partner)
    #retrieve app credentials for a particular partner
    #keys["partner"] #=> my key, my shared secret
  end
end

# External helpers

# RuLCP
# require './rblcp.rb'




