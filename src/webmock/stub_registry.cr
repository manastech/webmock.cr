struct WebMock::StubRegistry
  def initialize
    @stubs = [] of Stub
  end

  def stub(method, uri)
    stub = Stub.new(method, uri)
    @stubs << stub
    stub
  end

  def reset
    @stubs.clear
  end

  def find_stub(request)
    @stubs.find &.matches?(request)
  end

  def find_stub(method : String, uri : URI)
    @stubs.find &.matches?(method, uri)
  end
end
