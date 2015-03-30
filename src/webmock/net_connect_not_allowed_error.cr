class WebMock::NetConnectNotAllowedError < Exception
  def initialize
    super("Real HTTP connections are disabled")
  end
end
