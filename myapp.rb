# ==============================
# PLP
# Frank Caron
# Feb 2015
#
# A simple Storefront app for connecting to the Points LCP
# 
# ==============================

# |||| Reqs ||||

require "sinatra"

# |||| Default Settings ||||

set :views, Proc.new { File.join(settings.root, "/plp") }
set :public_folder, Proc.new { File.join(root, "plp") }
set :show_exceptions, true
set :static_cache_control, [:public, max_age: 0]

session = false
sessionID = ""

# ------------------------------
# Main Routes
# ------------------------------

before '/account/*' do
	validate_session()
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

  def validate_session()
    unless session && sessionID != nil
		redirect '/'
	end
  end
end

# External helpers

# RuLCP
require './rblcp.rb'




