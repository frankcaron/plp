# ==============================
# RuLCP
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


# Helpers

def generate_authorization_header_value(http_method,url,mac_key_identifier,mac_key,content_type,body)
    url_parts = urlparse.urlparse(url)
    port = url_parts.port
    if not port
        if url_parts.scheme == 'https'
            port = str(httplib.HTTPS_PORT)
        else
            port = str(httplib.HTTP_PORT)
        end
    end

    ts = str(int(time.time()))
    nonce = generate_nonce()
    ext = generate_ext(content_type, body)
    normalized_request_string = build_normalized_request_string(
        ts,
        nonce,
        http_method,
        url_parts.hostname,
        port,
        url_parts.path,
        ext)

    signature = generate_signature(mac_key, normalized_request_string)

    return "MAC id=" + mac_key_identifier + ", ts=" + ts + ", nonce=" + nonce + ", ext=" + ext + ", mac=" + signature + "' "
end

def generate_signature(mac_key, normalized_request_string)
    # Generate a request's MAC given a normalized request string (aka
    # a summary of the key elements of the request and the mac key (shared
    # secret).

    key = Base64.encode64(mac_key.replace('-', '+').replace('_', '/') + '=')
    signature = hmac.new(key, normalized_request_string, hashlib.sha1)
    return Base64.encode64(signature.digest())
end

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
        str(port) + '\n' + \
        ext + '\n'
    return normalized_request_string
end

def generate_ext(content_type, body)
    # Implements the notion of the ext as described in
    # http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-02#section-3.1"""
    if content_type != nil && body != nil && len(content_type) > 0 && len(body) > 0
        # Hashing requires a bytestring, so we need to encode back to utf-8
        # in case the body/header have already been decoded to unicode (by the
        # python json module for instance)
        if isinstance(body, unicode)
            body = body.encode('utf-8')
        end
        if isinstance(content_type, unicode)
            content_type = content_type.encode('utf-8')
        end
        content_type_plus_body = content_type + body
        content_type_plus_body_hash = hashlib.sha1(content_type_plus_body)
        ext = content_type_plus_body_hash.hexdigest()
    else
        ext = ""
    end
    return ext
end