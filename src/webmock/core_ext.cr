require "http/client"

class HTTP::Request
  getter scheme
  setter scheme : String = "http"
end

class HTTP::Client
  private def exec_internal(request : HTTP::Request)
    response = exec_internal(request) { |res| res }
    response.tap do |response|
      response.consume_body_io
      response.headers.delete("Transfer-encoding")
      response.headers["Content-length"] = response.body.bytesize.to_s
    end
  end

  private def exec_internal(request : HTTP::Request, &block : Response -> T) : T forall T
    request.scheme = "https" if tls?
    request.headers["Host"] = host_header unless request.headers.has_key?("Host")
    run_before_request_callbacks(request)

    stub = WebMock.find_stub(request)
    return yield(stub.exec(request)) if stub
    raise WebMock::NetConnectNotAllowedError.new(request) unless WebMock.allows_net_connect?

    request.headers["User-agent"] ||= "Crystal"
    request.to_io(socket)
    socket.flush

    result = nil

    HTTP::Client::Response.from_io(socket, request.ignore_body?) do |response|
      result = yield(response)
      close unless response.keep_alive?
      WebMock.callbacks.call(:after_live_request, request, response)
    end

    raise "Unexpected end of response" unless result.is_a?(T)

    result
  end
end
