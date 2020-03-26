require "http/client"

class HTTP::Request
  getter scheme
  setter scheme : String = "http"
end

class HTTP::Client
  private def exec_internal(request : HTTP::Request)
    before_request(request)
    WebMock.find_stub(request).try { |stub| return stub.exec(request) }

    perform_live_request(request)
  end

  private def exec_internal(request : HTTP::Request, &block : Response -> T) forall T
    before_request(request)
    WebMock.find_stub(request).try do |stub|
      stub.as_block
      return yield(stub.exec(request))
    end

    perform_live_request(request) do |response|
      yield response
    end
  end

  private def perform_live_request(request)
    send_live_request(request)
    receive_live_response(request)
  end

  private def perform_live_request(request, &block)
    send_live_request(request)
    receive_live_response(request) do |response|
      yield response
    end
  end

  private def receive_live_response(request)
    HTTP::Client::Response.from_io(socket, request.ignore_body?).tap do |response|
      after_live_request(request, response)
    end
  end

  private def receive_live_response(request, &block)
    HTTP::Client::Response.from_io(socket, request.ignore_body?) do |response|
      yield(response).tap do
        after_live_request(request, response)
      end
    end
  end

  private def after_live_request(request, response)
    close unless response.keep_alive?
    WebMock.callbacks.call(:after_live_request, request, response)
  end


  private def send_live_request(request)
    unless WebMock.allows_net_connect?
      raise WebMock::NetConnectNotAllowedError.new(request)
    end

    request.headers["User-agent"] ||= "Crystal"
    request.to_io(socket)
    socket.flush
  end

  private def before_request(request)
    request.scheme = "https" if tls?
    request.headers["Host"] = host_header unless request.headers.has_key?("Host")
    run_before_request_callbacks(request)
  end
end
