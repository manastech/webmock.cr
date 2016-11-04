describe WebMock::CallbackRegistry do

  it "takes a block" do
    callback = WebMock::CallbackRegistry.new
    callback.add do
      after_live_request do |request, response|
        "live_request"
      end
    end
    callback.callbacks.keys.should contain :after_live_request
  end
end
