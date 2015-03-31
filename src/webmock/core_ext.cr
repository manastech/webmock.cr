require "http/client"

class HTTP::Client
  def exec(request : HTTP::Request)
    stub = WebMock.find_stub(request)
    return stub.exec if stub

    if WebMock.allows_net_connect?
      previous_def
    else
      raise WebMock::NetConnectNotAllowedError.new(request)
    end
  end
end
