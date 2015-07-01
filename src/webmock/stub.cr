class WebMock::Stub
  def initialize(@method, uri)
    @uri = parse_uri(uri)

    # For to_return
    @status = 200
    @body = ""
    @headers = HTTP::Headers { "Content-length": "0" }
  end

  def with(query = nil, body = nil, headers = nil)
    @expected_query = query
    @expected_body = body
    @expected_headers = HTTP::Headers.new.merge!(headers) if headers
    self
  end

  def to_return(body = "", status = 200, headers = nil)
    @body = body
    @status = status
    @headers["Content-length"] = @body.length.to_s
    @headers.merge!(headers) if headers
    self
  end

  def matches?(request)
    matches_method?(request) &&
      matches_host?(request) &&
      matches_path?(request) &&
      matches_body?(request) &&
      matches_headers?(request)
  end

  def matches_method?(request)
    return true if @method == :any

    @method.to_s.upcase == request.method
  end

  def matches_host?(request)
    host_uri = parse_uri(request.headers["Host"])
    host_uri.host == @uri.host && host_uri.port == @uri.port
  end

  def matches_path?(request)
    uri_path = @uri.path || "/"
    uri_path = "/" if uri_path.empty?

    uri_query = @uri.query

    request_uri = parse_uri("http://example.com#{request.path}")
    request_path = request_uri.path
    request_query = request_uri.query

    request_query = request_query ? CGI.parse(request_query) : {} of String => Array(String)
    uri_query = uri_query ? CGI.parse(uri_query) : {} of String => Array(String)

    @expected_query.try &.each do |key, value|
      entry = uri_query[key.to_s] ||= [] of String
      entry << value.to_s
    end

    request_path == uri_path && request_query == uri_query
  end

  def matches_body?(request)
    @expected_body ? @expected_body == request.body : true
  end

  def matches_headers?(request)
    expected_headers = @expected_headers
    return true unless expected_headers

    expected_headers.each do |key, expected_value|
      value = request.headers[key]?
      return false unless value == expected_value.to_s
    end

    true
  end

  def exec
    HTTP::Response.new(@status, body: @body, headers: @headers)
  end

  private def parse_uri(uri_string)
    uri = URI.parse(uri_string)
    uri = URI.parse("http://#{uri_string}") unless uri.host
    uri
  end
end
