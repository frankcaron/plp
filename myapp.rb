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
require "./rblcp"

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

# Log In

get '/login' do
 	erb :login
end

get '/logged-in' do
	# Process Login
 	erb :signup
end

# Account Goodness

before '/account/*' do
	validate_session()
end

get '/profile' do
 	erb :profile
end

get '/give' do
 	erb :give
end

# Catch All

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





