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
require "digest/sha1"
require "openssl"
require "uri"
require "net/http"

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
    key = Base64.encode64(mac_key + '=')
    return Base64.encode64(OpenSSL::HMAC.digest('sha1',key, normalized_request_string))
end

def generate_ext(content_type, body)
    # Implements the notion of the ext as described in
    # http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-02#section-3.1"""
    if content_type != nil && body != nil && content_type.length > 0 && body.length > 0
        # Hashing requires a bytestring, so we need to encode back to utf-8
        # in case the body/header have already been decoded to unicode (by the
        # python json module for instance)
        body.encode("iso-8859-1").force_encoding("utf-8")
        content_type.encode("iso-8859-1").force_encoding("utf-8")
        content_type_plus_body = content_type + body
        ext = Digest::SHA1.hexdigest content_type_plus_body
    else
        ext = ""
    end
    return ext
end

def generate_authorization_header_value(http_method,url,mac_key_identifier,mac_key,content_type,body)
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
    normalized_request_string = build_normalized_request_string(
        ts,
        nonce,
        http_method,
        uri.host,
        port,
        uri.path,
        ext)

    signature = generate_signature(mac_key, normalized_request_string)

    return "MAC id=" + mac_key_identifier + ", ts=" + ts + ", nonce=" + nonce + ", ext=" + ext + ", mac=" + signature + "' "
end

# Tests

puts "Generated Signature: " + generate_signature("mac_key", "normalized_request_string")
puts "Normalized String: " + build_normalized_request_string("test", "nonce", "post", "lcp.points.com", "24", "/offers", "3") + "\n"
puts "Nonce: " + generate_nonce() + "\n"
puts "Generate Ext: " + generate_ext("test", "test")
puts "Generate Auth Header: " + generate_authorization_header_value("POST","http://lcp.points.com/v1/offers","test","test","test","test")

