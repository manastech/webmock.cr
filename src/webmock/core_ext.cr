require "http/client"

class HTTP::Client
  private def exec_internal(request : HTTP::Request)
    stub = WebMock.find_stub(request)
    return stub.exec if stub

    if WebMock.allows_net_connect?
      request.headers["User-agent"] ||= "Crystal"
      request.to_io(socket)
      socket.flush
      HTTP::Response.from_io(socket, request.ignore_body?).tap do |response|
        close unless response.keep_alive?
      end
    else
      raise WebMock::NetConnectNotAllowedError.new(request)
    end
  end
end
