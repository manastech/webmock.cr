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

  it "stubs http request with url (example with port)" do
    WebMock.wrap do
      WebMock.stub :any, "http://www.example.com:8080"

      response = HTTP::Client.get "http://www.example.com:8080"
      response.status_code.should eq(200)
      response.body.should eq("")
      response.headers["Content-length"].should eq("0")
    end
  end

  it "stubs http request with url (example with default port)" do
    WebMock.wrap do
      WebMock.stub :any, "http://www.example.com"

      response = HTTP::Client.get "http://www.example.com:80"
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

  it "stubs https request with url" do
    WebMock.wrap do
      WebMock.stub :any, "https://www.example.com"

      response = HTTP::Client.get "https://www.example.com"
      response.status_code.should eq(200)
    end
  end

  it "doesn't find stub and raises" do
    expect_no_match do
      HTTP::Client.get "http://www.example.com"
    end
  end

  it "doesn't find stub because scheme doesn't match" do
    WebMock.wrap do
      WebMock.stub :get, "http://www.example.com"

      expect_no_match do
        HTTP::Client.get "https://www.example.com"
      end
    end
  end

  it "doesn't find stub because host doesn't match" do
    WebMock.wrap do
      WebMock.stub :get, "www.crystal.com/foo"

      expect_no_match do
        HTTP::Client.get "http://www.example.com/foo"
      end
    end
  end

  it "doesn't find stub because port doesn't match" do
    WebMock.wrap do
      WebMock.stub :get, "www.example.com:8080/foo"

      expect_no_match do
        HTTP::Client.get "http://www.example.com/foo"
      end
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

  it "stubs and calls block for response" do
    WebMock.wrap do
      WebMock.stub(:post, "www.example.com").with(body: "Hello!").to_return do |request|
        headers = HTTP::Headers.new.merge!({ "Content-length" => "6" })
        HTTP::Client::Response.new(418, body: request.body.to_s.reverse, headers: headers)
      end

      response = HTTP::Client.post "http://www.example.com", body: "Hello!"
      response.body.should eq("!olleH")
      response.status_code.should eq(418)
      response.headers["Content-length"].should eq("6")
    end
  end

  it "stubs and returns body, with string method" do
    WebMock.wrap do
      WebMock.stub("get", "www.example.com").to_return(body: "Hello!")

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
      WebMock.stub(:get, "www.example.com").to_return(headers: {"foo" => "bar"})

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
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo" => "bar"}).to_return(body: "something")

      response = HTTP::Client.post("http://www.example.com", headers: HTTP::Headers{"foo" => "bar"})
      response.body.should eq("something")
    end
  end

  it "expects headers, allows integer" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(body: "abc", headers: {"Content-Length" => "3"}).to_return(body: "something")

      response = HTTP::Client.post("http://www.example.com", body: "abc")
      response.body.should eq("something")
    end
  end

  it "expects headers but doesn't match because of missing header" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo" => "bar"}).to_return(body: "something")

      expect_no_match do
        HTTP::Client.post("http://www.example.com")
      end
    end
  end

  it "expects headers but doesn't match because of wrong header value" do
    WebMock.wrap do
      WebMock.stub(:post, "http://www.example.com").with(headers: {"foo" => "bar"}).to_return(body: "something")

      expect_no_match do
        HTTP::Client.post("http://www.example.com", headers: HTTP::Headers{"foo" => "baz"})
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
      WebMock.stub(:get, "http://www.example.com").with(query: {"a" => "1", "b" => "2"})

      response = HTTP::Client.get "http://www.example.com?b=2&a=1"
      response.body.should eq("")
    end
  end

  it "contains stubbing instructions on failure" do
    WebMock.wrap do
      begin
        HTTP::Client.post("http://www.example.com/foo?a=1", body: "Hello!", headers: HTTP::Headers{"Foo" => "Bar"})
      rescue ex : WebMock::NetConnectNotAllowedError
        ex.message.not_nil!.strip.should eq(
          <<-MSG
          Real HTTP connections are disabled. Unregistered request: POST http://www.example.com/foo?a=1 with body "Hello!" with headers {"Foo" => "Bar", "Content-Length" => "6", "Host" => "www.example.com"}

          You can stub this request with the following snippet:

          WebMock.stub(:post, "http://www.example.com/foo?a=1").
            with(body: "Hello!", headers: {"Foo" => "Bar"}).
            to_return(body: "")
          MSG
        )
      end
    end
  end

  it "contains stubbing instructions on failure (without body not headers)" do
    WebMock.wrap do
      begin
        HTTP::Client.post("http://www.example.com/foo?a=1")
      rescue ex : WebMock::NetConnectNotAllowedError
        ex.message.not_nil!.strip.should eq(
          <<-MSG
          Real HTTP connections are disabled. Unregistered request: POST http://www.example.com/foo?a=1 with headers {"Content-Length" => "0", "Host" => "www.example.com"}

          You can stub this request with the following snippet:

          WebMock.stub(:post, "http://www.example.com/foo?a=1").
            to_return(body: "")
          MSG
        )
      end
    end
  end

  it "contains stubbing instructions on failure (with https url)" do
    WebMock.wrap do
      begin
        HTTP::Client.get("https://www.example.com/")
      rescue ex : WebMock::NetConnectNotAllowedError
        ex.message.not_nil!.strip.should eq(
          <<-MSG
          Real HTTP connections are disabled. Unregistered request: GET https://www.example.com/ with headers {"Host" => "www.example.com"}

          You can stub this request with the following snippet:

          WebMock.stub(:get, "https://www.example.com/").
            to_return(body: "")
          MSG
        )
      end
    end
  end

  it "works with request callbacks" do
    WebMock.wrap do
      WebMock.stub(:get, "http://www.example.com").with(query: {"foo" => "bar"})

      client = HTTP::Client.new "http://www.example.com"
      client.before_request do |request|
        request.query_params["foo"] = "bar"
      end
      client.get "/"
    end
  end

  describe ".calls" do
    it "returns 0 by default" do
      WebMock.wrap do
        stub = WebMock.stub :get, "www.crystal.com/foo"
        stub.calls.should eq(0)
      end
    end

    it "increments by one" do
      WebMock.wrap do
        stub = WebMock.stub :get, "www.crystal.com/foo"

        HTTP::Client.get "http://www.crystal.com/foo"

        stub.calls.should eq(1)
      end
    end

    it "increments multiple times" do
      WebMock.wrap do
        stub = WebMock.stub :get, "www.crystal.com/foo"

        3.times do
          HTTP::Client.get "http://www.crystal.com/foo"
        end

        stub.calls.should eq(3)
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
