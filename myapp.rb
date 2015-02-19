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

set :views, Proc.new { File.join(settings.root, "/base") }
set :public_folder, Proc.new { File.join(root, "base") }
set :show_exceptions, true
set :static_cache_control, [:public, max_age: 0]

# ------------------------------
# Partner-specific Landing Page
# ------------------------------
# Before any partner-specific visit, set up the views to point to the right partner folder

before '*' do
	lang = CSV.read("base/lang.csv")
	lang = Hash[lang.map {|key, value| [key, value]}]
	@lang = lang
end

get '/' do
 	erb :index
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
require './rulcp.rb'




