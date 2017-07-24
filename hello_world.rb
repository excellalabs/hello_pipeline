require 'sinatra/base'

class HelloWorld < Sinatra::Base
  get '/' do
    "<html><head><title>Hello World</title></head><body><h1>Hello World</h1></body></html>"
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
