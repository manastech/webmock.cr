class HaveRequestedExpectation
  @method : String
  @uri : URI

  def initialize(method : Symbol | String, uri)
    @method = method.to_s.upcase
    @uri = parse_uri(uri)
  end

  def match(target : WebMock)
    stub = target.find_stub(@method, @uri)
    return false if stub.nil?
    stub.calls >= 1
  end

  def failure_message(target : WebMock)
    "Expected at least 1 #{@method} request to #{@uri}, but no requests matched"
  end

  def negative_failure_message(target : WebMock)
    stub = target.find_stub(@method, @uri)
    actual_call_count = 
      if stub
        stub.calls
      else 
        0
      end
    "Expected no #{@method} requests to #{@uri}, but #{actual_call_count} request(s) matched"
  end

  private def parse_uri(uri_string)
    uri = URI.parse(uri_string)
    uri = URI.parse("http://#{uri_string}") unless uri.host
    uri
  end
end

def have_requested(method : Symbol | String, uri)
  HaveRequestedExpectation.new(method, uri)
end
