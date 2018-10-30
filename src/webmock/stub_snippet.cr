struct WebMock::StubSnippet
  def initialize(stub : Stub)
    @stub = stub
  end

  def to_s
    String.build do |io|
      io << "stub(:#{@stub.method.downcase}, \"#{@stub.uri}\""
      if body || headers
        io << ").\n  with(\n"
        if body
          io << "    body: \"#{body.to_s.gsub("\n", "\\n")}\""
          io << ",\n" if headers
        end
        if headers
          io << "    headers: {\n      "
          io << headers.not_nil!.map { |key, values| "\"#{key}\" => \"#{values.join(", ")}\"" }.join(",\n      ")
          io << "\n    }\n"
        else
          io << "\n"
        end
        io << "  )\n"
      end
      io << ")\n"
    end
  end

  private def body
    @stub.expected_body
  end

  private def headers
    @stub.expected_headers
  end
end
