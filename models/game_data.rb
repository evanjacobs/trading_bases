require 'gameday'
require 'nokogiri'

class GameData
  attr_accessor :game, :events

  def parse_game_data(game_id = '2012_07_24_nyamlb_seamlb_1')
    log = GamedayRemoteFetcher.fetch_eventlog(game_id)
    xml = Nokogiri::XML(log)

    home = Hash.new{|h,k| h[k] = []}
    visitor = Hash.new{|h,k| h[k] = []}

    home_team_name = ""
    visiting_team_name = ""
    xml.search('team').each{|t| t.attr('home_team').eql?('true') ? home_team_name = t.attr('name') : visiting_team_name = t.attr('name')}
    puts "home: #{home_team_name}, visitor: #{visiting_team_name}"

    xml.search('team[name="' + home_team_name + '"]//event').each do |e|
      home[e.attr('inning')] << "#{e.attr('description')}"
    end

    xml.search('team[name="' + visiting_team_name + '"]//event').each do |e|
      visitor[e.attr('inning')] << "#{e.attr('description')}"
    end

    @game = {"visitor" => visitor, "home" => home}
  end

  def play_game
    @events = Array.new
    for inning in 1..9
      @events << ["home_team_field"]
      @events << game['visitor'][inning.to_s]
      @events << ["visiting_team_field"]
      @events << game['home'][inning.to_s]
    end

    # If the home team doesn't take their last at-bats
    if @events.last.empty?
      @events.pop
      @events.pop
    end

    @events
  end
end
