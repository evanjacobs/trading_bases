require 'sinatra'
require 'sinatra/activerecord'
require 'delayed_job'
require 'delayed_job_active_record'
require 'pusher'

Pusher.app_id = ENV['PUSHER_APP_ID']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']

get '/' do
  erb :index
end

get '/game' do
  erb :game
end


