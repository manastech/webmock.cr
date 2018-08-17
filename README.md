# webmock.cr

[![Build Status](https://travis-ci.org/manastech/webmock.cr.svg?branch=master)](https://travis-ci.org/manastech/webmock.cr)

Library for stubbing `HTTP::Client` requests in [Crystal](http://crystal-lang.org/).

Inspired by [webmock ruby gem](https://github.com/bblimke/webmock).

## Installation

Add it to `shards.yml`:

```yaml
development_dependencies:
  webmock:
    github: manastech/webmock.cr
    branch: master
```

## Usage

```crystal
require "webmock"
```

By requiring `webmock` unregistered `HTTP::Client` requests will raise an exception.
If you still want to execute real requests, do this:

```crystal
WebMock.allow_net_connect = true
```

### Stub request based on uri only and with the default response

```crystal
WebMock.stub(:any, "www.example.com")

response = HTTP::Client.get("http://www.example.com")
response.body        #=> ""
response.status_code #=> 200
```

### Stub requests based on method, uri, body, headers and custom response

```crystal
WebMock.stub(:post, "www.example.com/foo").
  with(body: "abc", headers: {"Content-Type" => "text/plain"}).
  to_return(status: 500, body: "oops", headers: {"X-Error" => "true"})

response = HTTP::Client.post("http://www.example.com/foo",
                               body: "abc",
                               headers: HTTP::Headers{"Content-Type" => "text/plain"})
response.status_code        #=> 500
response.body               #=> "oops"
response.headers["X-Error"] #=> "true"

# Executing the same request gives the same response
response = HTTP::Client.post("http://www.example.com/foo",
                               body: "abc",
                               headers: HTTP::Headers{"Content-Type" => "text/plain"})
response.body               #=> "oops"
```

### Stub requests based on query string

```crystal
WebMock.stub(:get, "www.example.com").
  with(query: {"page" => "1", "count" => "10"})

response = HTTP::Client.get("http://www.example.com?count=10&page=1")
response.status_code #=> 200
```

### Stub requests and provide a block for the response

Your block will be called and passed the `HTTP::Request`, allowing you to construct a response dynamically based upon the request.

```crystal
WebMock.stub(:post, "www.example.com/foo").to_return do |request|
  headers = HTTP::Headers.new.merge!({ "Content-length" => request.body.to_s.length })
  HTTP::Client::Response.new(418, body: request.body.to_s.reverse, headers: headers)
end

response = HTTP::Client.post("http://www.example.com/foo",
                             body: "abc",
                             headers: HTTP::Headers{"Content-Type" => "text/plain"})
response.status_code               #=> 418
response.body                      #=> "cba"
response.headers["Content-length"] #=> "3"

response = HTTP::Client.post("http://www.example.com/foo",
                             body: "olleh",
                             headers: HTTP::Headers{"Content-Type" => "text/plain"})
response.status_code               #=> 418
response.body                      #=> "hello"
response.headers["Content-length"] #=> "5"
```

### Resetting

```crystal
WebMock.reset
```

This clears all stubs and sets `allow_net_connect` to `false`.

To execute this automatically before each spec, you can do:

```crystal
Spec.before_each &->WebMock.reset
```

Or, for individual specs you can use `WebMock.wrap` and a block to make sure `WebMock` is reset at the end of a spec:

```crystal
WebMock.wrap do
  WebMock.stub(:get, "www.example.com").to_return(body: "Example")

  HTTP::Client.get("http://www.example.com").body #=> "Example"
end

HTTP::Client.get("http://www.example.com") # Raises WebMock::NetConnectNotAllowedError
```

## Todo

Bring more features found in the [webmock ruby gem](https://github.com/bblimke/webmock).

## Contributing

1. Fork it ( https://github.com/manastech/webmock.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
