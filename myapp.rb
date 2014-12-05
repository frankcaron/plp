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
	# Determine the ab result
	ab_result = ab_test_init()

	# Display view
	if ab_result == 1
		erb :index

	else
		erb :index
	end
	
end

after '/*/' do
	# Set the views for the partner using request.path_info
	partnerOverride = "/partner/" + params[:splat][0]
end

# ------------------------------
# Generic Landing Page
# ------------------------------
# Catch all root visits

get '/' do
	partnerOverride = "base"
 	erb :index
end


# ------------------------------
# Helpers
# ------------------------------
# Helper functions

helpers do
  def ab_test_init()
    return 1 + rand(2)
  end
end




