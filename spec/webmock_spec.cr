require "./spec_helper"

private def expect_no_match
  expect_raises WebMock::NetConnectNotAllowedError, /Real HTTP connections are disabled/ do
    yield
  end
end

describe WebMock do
  it "stubs http request with url" do
    WebMock.wrap do
      WebMock.stub :any, "http://www.example.com"

      response = HTTP::Client.get "http://www.example.com"
      response.status_code.should eq(200)
      response.body.should eq("")
      response.headers["Content-length"].should eq("0")
    end
  end

  it "stubs http request with uri" do
    WebMock.wrap do
      WebMock.stub :any, "www.example.com"

      response = HTTP::Client.get "http://www.example.com"
      response.status_code.should eq(200)
    end
  end

  it "stubs http request with uri and path" do
    WebMock.wrap do
      WebMock.stub :any, "www.example.com/hello"

      response = HTTP::Client.get "http://www.example.com/hello"
      response.status_code.should eq(200)
    end
  end

  it "doesn't find stub and raises" do
    expect_no_match do
      HTTP::Client.get "http://www.example.com"
    end
  end

  it "doesn't find stub because path doesn't match" do
    WebMock.wrap do
      WebMock.stub :get, "www.example.com/foo"

      expect_no_match do
        HTTP::Client.get "http://www.example.com/bar"
      end
    end
  end

  it "stubs and returns body" do
    WebMock.wrap do
      WebMock.stub(:get, "www.example.com").to_return(body: "Hello!")

      response = HTTP::Client.get "http://www.example.com"
      response.body.should eq("Hello!")
      response.headers["Content-length"].should eq("6")
    end
  end

  it "stubs and returns status code" do
    WebMock.wrap do
      WebMock.stub(:get, "www.example.com").to_return(status: 300)

      response = HTTP::Client.get "http://www.example.com"
      response.status_code.should eq(300)
    end
  end

  it "stubs and returns headers" do
    WebMock.wrap do
      WebMock.stub(:get, "www.example.com").to_return(headers: {"foo": "bar"})

      response = HTTP::Client.get "http://www.example.com"
      response.headers["Foo"].should eq("bar")
    end
  end

  it "stubs multiple requests" do
    WebMock.wrap do
      WebMock.stub(:get, "www.example.com/one").to_return(body: "unu")
      WebMock.stub(:get, "www.example.com/two").to_return(body: "du")
      WebMock.stub(:get, "www.example.com/three").to_return(body: "tri")

      HTTP::Client.get("http://www.example.com/one").body.should eq("unu")
      HTTP::Client.get("http://www.example.com/two").body.should eq("du")
      HTTP::Client.get("http://www.example.com/three").body.should eq("tri")
    end
  end

  it "stubs indefinitely" do
    WebMock.wrap do
      WebMock.stub(:get, "www.example.com").to_return(body: "unu")

      HTTP::Client.get("http://www.example.com").body.should eq("unu")
      HTTP::Client.get("http://www.example.com").body.should eq("unu")
    end
  end

  it "expects body" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(body: "first").to_return(body: "second")

      response = HTTP::Client.post("http://www.example.com", body: "first")
      response.body.should eq("second")
    end
  end

  it "expects body but doesn't match" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(body: "first").to_return(body: "second")

      expect_no_match do
        HTTP::Client.post("http://www.example.com", body: "non-first")
      end
    end
  end

  it "expects headers" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo": "bar"}).to_return(body: "something")

      response = HTTP::Client.post("http://www.example.com", headers: HTTP::Headers{"foo": "bar"})
      response.body.should eq("something")
    end
  end

  it "expects headers, allows integer" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(body: "abc", headers: {"Content-Length": 3}).to_return(body: "something")

      response = HTTP::Client.post("http://www.example.com", body: "abc")
      response.body.should eq("something")
    end
  end

  it "expects headers but doesn't match because of missing header" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo": "bar"}).to_return(body: "something")

      expect_no_match do
        HTTP::Client.post("http://www.example.com")
      end
    end
  end

  it "expects headers but doesn't match because of wrong header value" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo": "bar"}).to_return(body: "something")

      expect_no_match do
        HTTP::Client.post("http://www.example.com", headers: HTTP::Headers{"foo": "baz"})
      end
    end
  end

  it "matches with query string in any order" do
    WebMock.wrap do
      WebMock.stub :get, "http://www.example.com?a=1&b=2"

      response = HTTP::Client.get "http://www.example.com?b=2&a=1"
      response.body.should eq("")
    end
  end

  it "doesn't match when query string doesn't match" do
    WebMock.wrap do
      WebMock.stub :get, "http://www.example.com?a=1&b=3"

      expect_no_match do
        HTTP::Client.get "http://www.example.com?b=2&a=1"
      end
    end
  end

  it "matches with query string in with" do
    WebMock.wrap do
      WebMock.stub(:get, "http://www.example.com").with(query: {"a": 1, "b": 2})

      response = HTTP::Client.get "http://www.example.com?b=2&a=1"
      response.body.should eq("")
    end
  end

  it "contains stubbing instructions on failure" do
    WebMock.wrap do
      begin
        HTTP::Client.post("http://www.example.com/foo?a=1", body: "Hello!", headers: HTTP::Headers{"Foo": "Bar"})
      rescue ex : WebMock::NetConnectNotAllowedError
        ex.message.strip.should eq(
<<-MSG
Real HTTP connections are disabled. Unregistered request: POST http://www.example.com with body "Hello!" with headers {"Foo" => "Bar", "Host" => "www.example.com", "Content-length" => "6"}

You can stub this request with the following snippet:

stub_request(:post, "www.example.com/foo?a=1").
  with(body: "Hello!", headers: {"Foo" => "Bar"}).
  to_return(body: "")
MSG
)
      end
    end
  end

  # Commented so that specs run fast, but uncomment to try it (it works)
  # it "allows net connect" do
  #   WebMock.wrap do
  #     WebMock.allow_net_connect = true

  #     HTTP::Client.get("http://www.example.com").body.should match(/Example Domain/)
  #   end
  # end
end
