require "./**"

module WebMock
  extend self

  @@allow_net_connect = false
  @@registry = StubRegistry.new
  @@callbacks = CallbackRegistry.new

  def wrap
    yield
  ensure
    reset
  end

  def stub(method, uri)
    @@registry.stub(method, uri)
  end

  def reset
    @@registry.reset
    @@allow_net_connect = false
  end

  def allow_net_connect=(@@allow_net_connect)
  end

  def allows_net_connect?
    @@allow_net_connect
  end

  def find_stub(request : HTTP::Request)
    @@registry.find_stub(request)
  end

  def callbacks
    @@callbacks
  end

  # :nodoc:
  def self.body(request : HTTP::Request)
    body = request.body.try(&.gets_to_end)
    if body
      request.body = IO::Memory.new(body)
    end
    body
  end
end
