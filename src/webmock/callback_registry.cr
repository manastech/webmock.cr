class WebMock::CallbackRegistry
  getter callbacks

  def initialize
    @callbacks = Hash(Symbol, (HTTP::Request, HTTP::Client::Response -> Nil)).new
  end

  def reset
    @callbacks.clear
  end

  def add
    with self yield
    self
  end

  def after_live_request(&block : (HTTP::Request, HTTP::Client::Response) ->)
    @callbacks[:after_live_request] = block
  end

  def call(name, *args)
    if !@callbacks.empty?
      @callbacks[name].try &.call(*args)
    end
  end
end
