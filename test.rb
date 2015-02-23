# ==============================
# Test
# Frank Caron
# Feb 2015
#
# A simple test for LCP connectivity
# ==============================

require "rest_client"
require "./rblcp"

# Real test
# url = "https://sandbox-staging.lcp.points.com/v1/lps/93eec35b-2aa1-45bf-866f-06f9de9c0b52/mvs/"

# mac_key_identifier = ENV["PLP_MAC_ID"]
# mac_key = ENV["PLP_MAC_KEY"]

# content_type = "application/json"
# body = { "firstName" => "John", "lastName" => "Doe 2000", "memberId" => "hhon" }.to_json
# headers = generate_authorization_header_value("POST",url,mac_key_identifier,mac_key,content_type,body)

# Debug
# puts "Mac ID: " + mac_key_identifier
# puts "Mac Key: " + mac_key
# puts "Headers: " + headers
# puts "Body: " + body
# RestClient.log = 'rest.log'

# Make request
# begin
#  response = RestClient.post(
#    url, 
 #   body,
 #   :content_type => :json, :accept => :json, :"Authorization" => headers)
#rescue => e
#  e.response
#end

#puts response.to_str