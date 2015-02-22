# ==============================
# RbLCP
# Frank Caron
# Feb 2015
#
# Basic helpers for connecting to Points' Loyalty Commerce Platform
# Adapted from pylcp: https://github.com/Points/PyLCP
# 
# ==============================

# Reqs

require "Base64"
require "SecureRandom"
require "openssl"
require "uri"
require "net/http"
require "rest_client"
require "CGI"

# Helpers

def generate_nonce()
    # Generates a random string intend for use as a nonce when computing an HMAC.
    return SecureRandom.hex(8)
end

def build_normalized_request_string(ts, nonce, http_method, host, port, request_path, ext)
    # Implements the notion of a normalized request string as described in
    # http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-02#section-3.2.1

    normalized_request_string = \
        ts + '\n' + \
        nonce + '\n' + \
        http_method + '\n' + \
        request_path + '\n' + \
        host + '\n' + \
        port.to_s + '\n' + \
        ext + '\n'
    return normalized_request_string
end

def generate_signature(mac_key, normalized_request_string)
    # Generate a request's MAC given a normalized request string (aka
    # a summary of the key elements of the request and the mac key (shared
    # secret).

    # Do subs
    mac_key = mac_key.gsub('-', '+')
    mac_key = mac_key.gsub('_', '/')
    mac_key += '=' * (4 - mac_key.length % 4)
    #key = Base64.urlsafe_decode64(mac_key)
    key = Base64.decode64(mac_key)
    return Base64.encode64(OpenSSL::HMAC.digest('SHA1',key,normalized_request_string)).strip
    #return OpenSSL::HMAC.hexdigest('SHA1',key,normalized_request_string)
end

def generate_ext(content_type, body)
    # Implements the notion of the ext as described in
    # http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-02#section-3.1"""
    if content_type != nil && body != nil && content_type.length > 0 && body.length > 0
        # Hashing requires a bytestring, so we need to encode back to utf-8
        # in case the body/header have already been decoded to unicode
        unless body.encoding == Encoding::ISO_8859_1
            body.encode("iso-8859-1").force_encoding("utf-8")
        end
        unless content_type.encoding == Encoding::ISO_8859_1
            content_type.encode("iso-8859-1").force_encoding("utf-8")
        end
        ext = OpenSSL::Digest::SHA1.hexdigest(content_type + body)
    else
        ext = ""
    end
    return ext
end

def generate_authorization_header_value(http_method,url,mac_key_identifier,mac_key,content_type,body)

    # Gather the bits and pieces for the request string
    uri = URI(url)
    port = uri.port
    unless port != nil
        if uri.scheme == 'https'
            port = Net::HTTP.https_default_port().to_s
        else
            port = Net::HTTP.default_port().to_s
        end
    end
    ts = Time.now().to_i.to_s
    nonce = generate_nonce()
    ext = generate_ext(content_type, body)

    # Create the signature of legend

    normalized_request_string = build_normalized_request_string(ts,nonce,http_method,uri.host,port,uri.path,ext)
    signature = generate_signature(mac_key,normalized_request_string)

    # Return the auth header
    return 'MAC id="' + mac_key_identifier + '", ts="' + ts + '", nonce="' + nonce + '", ext="' + ext + '", mac="' + signature + '"'
end

# Tests

# puts "Generated Signature: " + generate_signature("mac_key", "normalized_request_string")
# puts "Normalized String: " + build_normalized_request_string("test", "nonce", "post", "lcp.points.com", "24", "/offers", "3") + "\n"
# puts "Nonce: " + generate_nonce() + "\n"
# puts "Generate Ext: " + generate_ext("test", "test")
# puts "Generate Auth Header: " + generate_authorization_header_value("POST","http://lcp.points.com/v1/offers","test","test","test","test")

# Real test
url = "https://sandbox-staging.lcp.points.com/v1/lps/93eec35b-2aa1-45bf-866f-06f9de9c0b52/mvs/"
mac_key_identifier = ENV["PLP_MAC_ID"]
mac_key = ENV["PLP_MAC_KEY"]
content_type = "application/json"
body = { "firstName" => "John", "lastName" => "Doe 2000", "memberId" => "dVNm" }.to_json
headers = generate_authorization_header_value("POST",url,mac_key_identifier,mac_key,content_type,body)

# Debug
puts "Mac ID: " + mac_key_identifier
puts "Mac Key: " + mac_key
puts "Headers: " + headers
puts "Body: " + body
 RestClient.log = 'rest.log'

# Make request
begin
  response = RestClient.post(
    url, 
    body,
    :content_type => :json, :accept => :json, :"Authorization" => headers)
rescue => e
  e.response
end

puts e
