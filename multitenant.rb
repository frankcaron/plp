# ==============================
# Mulitenant Storefront App
# Frank Caron
# December 2014
#
# This app provides a simple framework for a multi-tenant, white-label 
# eCommerce storefront.
# 
# ==============================

# |||| Reqs ||||

require 'sinatra'
require 'csv'

# |||| Global vars ||||

partnerOverride = "base"

# |||| Default Settings ||||

set :views, Proc.new { File.join(settings.root, "/" + partnerOverride) }
set :public_folder, Proc.new { File.join(root, partnerOverride) }
set :show_exceptions, true
set :static_cache_control, [:public, max_age: 0]

# ------------------------------
# Partner-specific Landing Page
# ------------------------------
# Before any partner-specific visit, set up the views to point to the right partner folder

before '/*/' do
	# Set the views for the partner using request.path_info
	partnerOverride = "partner/" + params[:splat][0]
end

get '/*/' do
	#Grab lang
	begin
		lang = CSV.read(partnerOverride + "/lang.csv")
	rescue
		lang = CSV.read("base/lang.csv")
	end

	lang = Hash[lang.map {|key, value| [key, value]}]
	@lang = lang	

	# Display view
	if ab_test_init() == 1
		begin
			erb :index
		rescue
			partnerOverride = "base"
			erb :index
		end
	else
		begin
			erb :index_alternate
		rescue
			begin
				erb :index
			rescue
				partnerOverride = "base"
				erb :index
			end
		end
	end
	
end

after '/*/' do
	# Set the views for the partner using request.path_info
	partnerOverride = "partner/" + params[:splat][0]
end

# ------------------------------
# Generic Landing Page
# ------------------------------
# Catch all root visits

before '*' do
	lang = CSV.read("base/lang.csv")
	lang = Hash[lang.map {|key, value| [key, value]}]
	@lang = lang
end

get '/' do
	partnerOverride = "base"
 	erb :plp_index
end

get '/*' do
	partnerOverride = "base"
 	erb :plp_index
end


# ------------------------------
# Helpers
# ------------------------------
# Helper functions

helpers do
  def ab_test_init()
    return 1 + rand(2)
  end

  def determine_app_credentials(partner)
    #retrieve app credentials for a particular partner
    #keys["partner"] #=> my key, my shared secret
  end
end