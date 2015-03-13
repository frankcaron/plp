# ==============================
# PLP
# Frank Caron
# Feb 2015
#
# A simple Storefront and Fulfillment app for connecting to the Points LCP
# 
# ==============================

# |||| Depedencies ||||

require "sinatra"
require "rack-ssl-enforcer"
require "rest_client"
require "json"

# RbLCP
require "./rblcp"

# ------------------------------------------------------------------------------------------
# |||| Default Settings ||||
# ------------------------------------------------------------------------------------------

configure do
    # File locations
    set :views, Proc.new { File.join(settings.root, "/plp") }
    set :public_folder, Proc.new { File.join(root, "plp") }
    set :show_exceptions, true
    set :static_cache_control, [:public, max_age: 0]

    # PICs
    set :base_give_pic, "PointsForGood"
    set :base_url, "https://staging.lcp.points.com/v1"
    set :plp_registration_url, "https://plp-api.herokuapp.com/register"

    # Enable :sessions
    use Rack::Session::Pool
end

configure :production do
  use Rack::SslEnforcer
end

# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# Main Routes
# ------------------------------------------------------------------------------------------

# Log In

get '/login' do
    kill_session()
    erb :login
end

get '/logged-in' do
    # Grab Token
    accessToken = params[:token]

    unless accessToken.nil?
        # Set Session
        session[:session] = true
        session[:sessionToken] = accessToken

        # Logging 
        puts "LOG | Session: " + session[:session].to_s
        puts "LOG | Session Token: " + session[:sessionToken]

        #Fetch the member details
        session[:sessionMember] = fetch_deets(session[:sessionToken])

        # Logging 
        puts "LOG | Session Member: " + session[:sessionMember].to_s
        puts "LOG | Session Member Name: " + session[:sessionMember]["name"]["givenName"]
        puts "LOG | Session Member Domain: " + session[:sessionMember]["domain"]

        unless session[:sessionMember]["domain"].to_s.eql? "points.com"
          # Redirect to the error page if the person isn't from Points
          puts "LOG | Session Member isn't a Points.com member"
          redirect '/error'
        end

        # Construct user object
        user = {"firstName" => session[:sessionMember]["name"]["givenName"], "lastName" => session[:sessionMember]["name"]["familyName"], "email" => session[:sessionMember]["emails"][0]["value"].to_s}
    
        #Do an MV
        session[:sessionMV] = JSON.parse(create_mv(user, 1))

        # Logging
        puts "LOG | SESSION MV"
        puts session[:sessionMV].to_s
        puts "LOG | SESSION Balance"
        puts session[:sessionMV]["balance"]
        puts "LOG | SESSION first name"
        puts session[:sessionMV]["firstName"]

        # Redirect to profile once account created successfully
        redirect '/account/profile'
        
    end
  # Redirect back to log in page if something goes wrong
  redirect '/login'
end

# Account Goodness

before '/account/*' do
    validate_session(session[:session],session[:sessionToken])
end


get '/account/logout' do
    kill_session()
    erb :logout
end

get '/account/profile' do
    
    #Do a fresh MV
    user = {"firstName" => session[:sessionMember]["name"]["givenName"], "lastName" => session[:sessionMember]["name"]["familyName"], "email" => session[:sessionMember]["emails"][0]["value"].to_s}
    session[:sessionMV] = JSON.parse(create_mv(user, 0))

    #Pass session details to view
    @mv = session[:sessionMV]
    @session = session[:session]

    #Load view
    erb :profile
end

get '/account/give' do
    #Pass session details to view
    @mv = session[:sessionMV]
    @session = session[:session]

    # Load view
    erb :give
end


get '/account/activity' do
    #Pass session details to view
    @mv = session[:sessionMV]
    @session = session[:session]

    #Grab params
    limit = params[:limit]
    offset = params[:offset]

    #Tweak params
    if offset.nil? || offset.to_i < 0
      offset = "0"
    end
    if limit.nil? || limit.to_i > 10
      limit = "5" 
    end

    @next = offset.to_i + limit.to_i
    @prev = offset.to_i - limit.to_i

    # Grab the activity
    begin
        # Log
        puts "LOG | Getting order activity "
        puts "LOG | (Limit, Offset) " + limit + "," + offset

        # Get the orders
        url = settings.base_url + "/search/orders/?limit=" + limit + "&offset=" + offset +  "&q=orderType:PointsIncentive&sort=createdAt:desc"
        orders = call_lcp("GET",url,"")
        orders = JSON.parse(orders)

        # Log
        puts "LOG | Order activity | " + orders.to_s

        # Pass the session
        @orders = orders

        #Load the view
        erb :activity
    rescue => e
        # Log the response
        puts "LOG | Failed to get orders | " + e.to_s
        # Redirect to the error page
        redirect '/error'
    end       
end

get '/account/get' do

    #Pass session details to view
    @mv = session[:sessionMV]
    @session = session[:session]
    
    erb :get_points
end

post '/account/give-points' do
    #Grab params
    firstName = params[:firstName]
    lastName = params[:lastName]
    email = params[:email]
    points = params[:points]
    message = params[:message]

    #Params
    puts "LOG | Form Post | First Name " + firstName.to_s
    puts "LOG | Form Post | Last Name " + lastName.to_s
    puts "LOG | Form Post | Email " + email.to_s

    # Structure data
    pic = settings.base_give_pic
    recipient = { "firstName" => firstName, "lastName" => lastName, "email" => email }

    # Do the Gift
    begin
        puts "LOG | Gifting to a member " + recipient.to_s
        credit_member(recipient, points, pic, message)

        puts "LOG | Successfully gifted " + points

        # Redirect to the account page
        redirect '/account/profile'
    rescue => e
        # Log the response
        puts "LOG | Failed to credit member | " + e.to_s
        # Redirect to the error page
        redirect '/error'
    end   
end

post '/account/get-points' do
    # Pass session details to view
    # credit_member(self)
    #Grab params
    points = params[:points]
    message = params[:message]

    #Params
    puts "LOG | Form Post | Points " + points
    puts "LOG | Form Post | Message " + message

    # Structure data
    pic = settings.base_give_pic
    recipient = { "firstName" => session[:sessionMV]["firstName"], "lastName" => session[:sessionMV]["lastName"], "email" => session[:sessionMV]["email"] }

    # Do the Gift
    begin
        puts "LOG | Self gifting to a member " + recipient.to_s
        credit_member(recipient, points.to_i, pic, message)

        puts "LOG | Successfully self gifted " + points

        # Redirect to the account page
        redirect '/account/profile'
    rescue => e
        # Log the response
        puts "LOG | Failed to credit member | " + e.to_s
        # Redirect to the error page
        redirect '/error'
    end    
end

# Catch All

get '/error' do
    erb :error
end

get '/*' do
    erb :index
end


# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------------------
# Helper functions

helpers do

  # =====================
  # Session Validator
  #
  # Used to validate that a session is legitimate for security.
  # ======================

  def validate_session(session,token)
    unless session  && token != ""
        redirect '/'
    end
  end

  # =====================
  # Session Killer
  #
  # Used to kill a session for logout, etc.
  # ======================

  def kill_session
    session[:session] = false
    session[:sessionToken] = ""
    session[:sessionMember] = ""
    session[:sessionMV] = ""
  end  


  # =====================
  # Fetch Google Account Details
  #
  # Used for Google Account login to fetch the member's details from Google
  # Primarily used for Single Sign-on
  # ======================

  def fetch_deets(token)
    # GET 
    url = "https://www.googleapis.com/plus/v1/people/me?access_token=" + token
    # Make Request
    begin
        response = RestClient.get(
            url, 
            :content_type => :json, :accept => :json)
        # Stuff response in
        return JSON.parse(response.to_str)
    rescue => e
        # Log the response
        puts "LOG | Details fetch error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
    end
  end  

  # =====================
  # Create MV
  #
  # Creates an MV given the input
  # Special instance here will automatically create an account in the PLP
  # ======================

  def create_mv(user, newUser)

    puts "LOG | Creating MV"

    # Set up basics
    url = settings.base_url + "/lps/53678d34-92c7-46c3-942b-d195ccf33637/mvs/"
    method = "POST"
    body = { "memberId" => user["email"] }.to_json

    puts "LOG | MV body to create | " + body

    # Make Request
    begin
      mvresponse = call_lcp(method,url,body)
      
      # Log the MV fetch
      puts "LOG | MV created successfully | " + mvresponse.to_s

      # Fetch the member details
      mvs = JSON.parse(mvresponse)
      detailsURL = mvs["links"]["self"]["href"]+"/member-details"
      puts "LOG | Grabbing member details | " + detailsURL

      begin
        # Return Response
        response = call_lcp("GET",detailsURL,"")
        puts "LOG | MV Details fetched successfully | " + response.to_s
        return response

      rescue => e
        puts "LOG | MV Details create error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
      end
      
    rescue => e
      # If the member doesn't exist, create an account.
      puts "LOG | Error creating MV | Trying to create account | " + e.to_s
      if e.response.code == 422
        if newUser == 1
          points = 2000
          create_account(user["firstName"],user["lastName"],user["email"],points)

          puts "LOG | Account successfully created"
          return create_mv(user,0)
        end       
      else 
        # Log the response
        puts "LOG | MV create error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
      end
    end
  end

  # =====================
  # Create Account
  #
  # Creates an account for a member in the PLP via its APIs
  # ======================

  def create_account(firstName,lastName,email,points)
    # Create an account with Mihnea's LP
    
    # Set request
    url = settings.plp_registration_url
    content_type = "application/json"
    
    # Set up picture
    picture = session[:sessionMember]["image"]["url"]
    if picture.nil?
      picture = "http://3.bp.blogspot.com/-G5aIFyMZ7f0/T70hqGlbb5I/AAAAAAAAK_Q/FYMbyJz2SXU/s1600/Question_mark.PNG"
    end

    body = { "memberId" => email, "firstName" => firstName, "lastName" => lastName, "points" => points, "picture" => picture  }.to_json
    
    # Make Request
    begin
        response = RestClient.post(
            url, body, 
            :content_type => :json, :accept => :json)

            puts "LOG | Account create response | " + response.to_str
    rescue => e
        # Log the response
        puts "LOG | Account create error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
    end
  end

  # =====================
  # Credit member
  #
  # Creates a credit and order for a member
  # This special admin version is used for the activity awarding
  # ======================
  def credit_member(recipient, points, pic, message)
    # If the member is an admin
    #unless session[:sessionMV]["admin"].nil?
      #Create recipient MV
      puts "creatingMV"
      userMV = session[:sessionMV]
      recipientMV = JSON.parse(create_mv(recipient, 0))
      puts "recpievntMV"
      puts recipientMV
      
      puts "creatingOrder"
      #Create order
      order = JSON.parse(create_order(recipientMV, points, pic, message))
      #Patch MVs

      patch_mv(userMV,order)
      patch_mv(recipientMV,order)
      
      #Create Credit
      create_credit(recipientMV, points, pic)
      #end
  end

  # =====================
  # Create Order
  #
  # Creates a new order on the LCP
  # ======================
  def create_order(recipientMV, points, pic, message)
    orderType = "PointsIncentive"
    
    #Order Data Section
    loyaltyProgram = session[:sessionMV]["loyaltyProgram"]
    user = {"firstName" => session[:sessionMV]["firstName"],    #TODO: cleanup to use this from the MV
            "lastName" => session[:sessionMV]["lastName"], 
            #"email" => session[:sessionMV]["email"], 
            "balance" => session[:sessionMV]["balance"],
            "picture" => session[:sessionMV]["picture"]} 
    recipient = {"firstName" => recipientMV["firstName"],
                 "lastName" => recipientMV["lastName"], 
                 #"email" => recipientMV["email"], 
                 "balance" => recipientMV["balance"]}
    basePIC = {"base" => pic}
    orderDetails = {"basePoints" => points, "recipientMessage" => message, "pic" => basePIC}
    orderData = {"loyaltyProgram" => loyaltyProgram, "user" => user, "recipient" => recipient, "orderDetails" => orderDetails}
    url = settings.base_url + "/orders/"
    method = "POST"
    body = {"orderType" => orderType, "data" => orderData}.to_json
    
    begin
        puts "LOG | ORDER creating" 
        response = call_lcp(method,url,body)
    rescue => e
      if e.response.code == 500
        puts "LOG | ORDER create returned 500"      
      else 
        # Log the response
        puts "LOG | ORDER create error | " + e.to_s
      end
      # Redirect to the error page
      redirect '/error'
    end

    # Log the response
    puts "LOG | ORDER created |"

    # Return the response
    return response

    ## TODO: add error cases for 400+ errors
  end

  # =====================
  # Patch MV
  #
  # Patches and MV with an order resource
  # ======================
  def patch_mv(mv,order)
    url = mv["links"]["memberValidation"]["href"]
    method = "PATCH"

    body = { "order" => order["links"]["self"]["href"] }.to_json

    begin
      response = call_lcp(method,url,body)
    rescue => e
      if e.response.code == 500
        puts "LOG | CREDIT create returned 500"     
      else 
        # Log the response
        puts "LOG | CREDIT create error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
      end
    end
  ## TODO: add error cases for 400+ errors

  end

  # =====================
  # Create Credit
  #
  # Creates a new credit on the LCP
  # ======================
  def create_credit(recipientMV,points,pic)
    memberValidation = recipientMV["links"]["memberValidation"]["href"]

    url = settings.base_url + "/lps/53678d34-92c7-46c3-942b-d195ccf33637/credits/"
    method = "POST"
    body = {"amount" => points, "pic" => pic, "memberValidation" => memberValidation}.to_json

    begin
      response = call_lcp(method,url,body)
    rescue => e
      if e.response.code == 500
        puts "LOG | CREDIT create returned 500"     
      else 
        # Log the response
        puts "LOG | CREDIT create error | " + e.to_s
        # Redirect to the error page
        redirect '/error'
      end
    end
  ## TODO: add error cases for 400+ errors, failure status, etc
  end

  # =====================
  # Call LCP
  #
  # Generic LCP call wrapper
  # ======================

  def call_lcp(method,url,body)

    # Logging
    puts "LOG | Calling to LCP | Prep"
    puts "LOG | Calling to LCP | url: " + url
    puts "LOG | Calling to LCP | method: " + method 
    puts "LOG | Calling to LCP | body: " + body.to_s

    # Prep vars
    mac_key_identifier = ENV["PLP_MAC_ID"]
    mac_key = ENV["PLP_MAC_KEY"]
    method = method.upcase

    # Ignore content type if the GET 
    if method != "GET"
      content_type = "application/json"
    else
      content_type = ""
    end

    # Generate Headers
    headers = generate_authorization_header_value(method,url,mac_key_identifier,mac_key,content_type,body)

    # Logging   
    puts "LOG | Calling to LCP | headers: " + headers

    # Make Request
    if method == "POST"
      return RestClient.post(url, 
                   body, 
                   :content_type => :json, 
                   :accept => :json,
                   :"Authorization" => headers)
    elsif method == "PATCH"    
      return RestClient.patch(url, 
                  body, 
                  :content_type => :json, 
                  :accept => :json,
                  :"Authorization" => headers)
    elsif method == "GET"    
      return RestClient.get(url, 
                  :accept => :json,
                  :"Authorization" => headers)
    else
      return RestClient.get(url, 
                  body,
                  :content_type => :json, 
                  :accept => :json,
                  :"Authorization" => headers)
    end
  end 
#
end