#!/usr/bin/env ruby

require 'yaml'
require 'twitter'

config_file = File.dirname(__FILE__) + '/config.yml'

if !File.exist?(config_file)
  raise "Configuration file " + config_file + " missing!"
end

CONFIG = YAML.load_file(config_file)

sclient = Twitter::Streaming::Client.new do |config|
  config.consumer_key = CONFIG['twitter']['consumer_key']
  config.consumer_secret = CONFIG['twitter']['consumer_secret']
  config.oauth_token = CONFIG['twitter']['oauth_token']
  config.oauth_token_secret = CONFIG['twitter']['oauth_token_secret']
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key = CONFIG['twitter']['consumer_key']
  config.consumer_secret = CONFIG['twitter']['consumer_secret']
  config.oauth_token = CONFIG['twitter']['oauth_token']
  config.oauth_token_secret = CONFIG['twitter']['oauth_token_secret']
end

sclient.user do |object|
  case object
    when Twitter::Tweet
      if object.text.downcase.include? '@' + client.user.screen_name.downcase
        tries ||= 5
        begin
          begin
            tweet_text = '@' + object.user.screen_name + ' ' + CONFIG['twitter']['tweet_prefix'] + ' ' + CONFIG['twitter']['tweets'].sample
          end until tweet_text.length <= 140
          client.update(tweet_text, :in_reply_to_status_id => object.id)
          puts tweet_text
          tries = 5
        rescue Twitter::Error => e
          puts e.message
          puts e.backtrace.inspect
          if (tries -= 1) > 0
            retry
          else
            puts "Too many failures, tweet not sent!"
          end
        end
      end
  end
end
