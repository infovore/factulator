require 'rubygems'
require 'sequel'
require 'rss/2.0'
require 'rss/itunes'

DB = Sequel.sqlite('factulator.db')
podcasts = DB[:podcasts].all

author = "FACT magazine"

rss = RSS::Rss.new("2.0")
channel = RSS::Rss::Channel.new

channel.title = "FACT mixes"
channel.description = "Latest mixes from FACT magazine"
channel.link= "http://www.factmag.com/category/factmixes/"
channel.language = "en-us"
channel.lastBuildDate = Time.now


podcasts.each do |podcast|
  item = RSS::Rss::Channel::Item.new
  item.title = podcast[:title]
  link = podcast[:url]
  item.link = link
  item.guid = RSS::Rss::Channel::Item::Guid.new
  item.guid.content = link
  item.guid.isPermaLink = true
  item.pubDate = podcast[:created_at]

  # file_size = podcast[:file_size]
  file_size = 1
 
  item.enclosure = RSS::Rss::Channel::Item::Enclosure.new(item.link, file_size, 'audio/mpeg')     
  channel.items << item
   
  end

rss.channel = channel

puts rss.to_s
