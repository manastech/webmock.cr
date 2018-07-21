require "http/client"

class HTTP::Request
  getter scheme
  setter scheme : String = "http"
end

class HTTP::Client
  private def exec_internal(request : HTTP::Request)
    request.scheme = "https" if tls?
    run_before_request_callbacks(request)
    stub = WebMock.find_stub(request)
    return stub.exec(request) if stub

    if WebMock.allows_net_connect?
      request.headers["User-agent"] ||= "Crystal"
      request.to_io(socket)
      socket.flush
      res = HTTP::Client::Response.from_io(socket, request.ignore_body?).tap do |response|
        close unless response.keep_alive?
      end
      WebMock.callbacks.call(:after_live_request, request, res)
      res
    else
      raise WebMock::NetConnectNotAllowedError.new(request)
    end
  end
end
