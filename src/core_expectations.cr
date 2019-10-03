abstract class StubCallCountMatcher 
  abstract def match(stub : WebMock::Stub?) : Bool
  abstract def failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
  abstract def negative_failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String

  protected def get_actual_call_count(stub : WebMock::Stub?)
    if stub
      stub.calls
    else
      0
    end
  end
end
class AtLeastStubCallCountMatcher < StubCallCountMatcher
  def initialize(@times : Int32)
  end
  def match(stub : WebMock::Stub?) : Bool
    return false if stub.nil?
    stub.calls >= @times
  end
  def failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected at least #{@times} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
  def negative_failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected fewer than #{@times} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
end
class AtMostStubCallCountMatcher < StubCallCountMatcher
  def initialize(@times : Int32)
  end
  def match(stub : WebMock::Stub?) : Bool
    return false if stub.nil?
    stub.calls <= @times
  end
  def failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected at most #{@times} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
  def negative_failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected more than #{@times} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
end
class ExactlyNStubCallCountMatcher < StubCallCountMatcher
  def initialize(@n : Int32)
  end
  def match(stub : WebMock::Stub?) : Bool
    return false if stub.nil?
    stub.calls == @n
  end
  def failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected at least #{@n} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
  def negative_failure_message(method : String, uri : URI, stub : WebMock::Stub?) : String
    "Expected exactly #{@n} #{method} requests to #{uri}, but #{get_actual_call_count(stub)} request(s) matched"
  end
end
class HaveRequestedExpectation
  @call_count_matcher : StubCallCountMatcher
  @method : String
  @uri : URI

  def initialize(method : Symbol | String, uri)
    @method = method.to_s.upcase
    @uri = parse_uri(uri)
    @call_count_matcher = AtLeastStubCallCountMatcher.new(1)
  end

  def once
    @call_count_matcher = ExactlyNStubCallCountMatcher.new(1)
    self
  end

  def at_least_n_times(n : Int32)
    @call_count_matcher = AtLeastStubCallCountMatcher.new(n)
    self
  end

  def times(n : Int32)
    @call_count_matcher = ExactlyNStubCallCountMatcher.new(n)
    self
  end

  def at_most_n_times(n : Int32)
    @call_count_matcher = AtMostStubCallCountMatcher.new(n)
    self
  end

  def match(target : WebMock)
    stub = target.find_stub(@method, @uri)
    @call_count_matcher.match(stub)
  end

  def failure_message(target : WebMock)
    stub = target.find_stub(@method, @uri)
    @call_count_matcher.failure_message(@method, @uri, stub)
  end

  def negative_failure_message(target : WebMock)
    stub = target.find_stub(@method, @uri)
    @call_count_matcher.negative_failure_message(@method, @uri, stub)
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
