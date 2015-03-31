class WebMock::NetConnectNotAllowedError < Exception
  def initialize(request : HTTP::Request)
    super(help_message(request))
  end

  private def help_message(request)
    String.build do |io|
      io << "Real HTTP connections are disabled. "
      io << "Unregistered request: "
      signature(request, io)
      io << "\n\n"
      io << "You can stub this request with the following snippet:"
      io << "\n\n"
      stubbing_instructions(request, io)
      io << "\n\n"
    end
  end

  private def signature(request, io)
    io << request.method << " http://" << request.headers["Host"]
    if request.body
      io << " with body "
      request.body.inspect(io)
    end
    io << " with headers " << request.headers.to_h
  end

  private def stubbing_instructions(request, io)
    io << "stub_request(:" << request.method.downcase << ", "
    io << '"' << request.headers["Host"] << request.path << %[").]
    io.puts
    io << "  with("

    # For the instructions we remove these two headers because they are automatically
    # included in HTTP::Client requests
    headers = request.headers.dup
    headers.delete("Content-Length")
    headers.delete("Host")

    if request.body
      io << "body: "
      request.body.inspect(io)
      io << ", " unless headers.empty?
    end

    io << "headers: " << headers.to_h unless headers.empty?
    io << ")."
    io.puts
    io << %[  to_return(body: "")]
  end
end
