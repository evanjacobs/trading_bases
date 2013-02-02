require 'sinatra'
require 'sinatra/activerecord'
require 'delayed_job'
require 'delayed_job_active_record'
require 'gameday_api'

get '/' do
  'Hello, world!'
end

