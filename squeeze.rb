require 'sinatra'
require 'sinatra/activerecord'
require 'delayed_job'
require 'delayed_job_active_record'
require 'pusher'

Pusher.app_id = 36617
Pusher.key = 'c1c5221d995f9bec3010'
Pusher.secret = '09d04d8fea0a1a6769ea'

get '/' do
  erb :index
end

