require 'sinatra'
require 'pusher'

Pusher.app_id = 36615
Pusher.key = 'a7777090afd53215b48f'
Pusher.secret = '001963c7e6250d50d1a6'

get '/' do
  erb :index
end

