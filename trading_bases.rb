require 'sinatra'
require 'pusher'
require './models/game_data'

Pusher.app_id = ENV['PUSHER_APP_ID']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']

get '/' do
  erb :index
end

get '/game' do
  erb :game
end


