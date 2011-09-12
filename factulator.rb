#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'sequel'

PATH_PREFIX = File.expand_path(File.dirname(__FILE__))

DB = Sequel.sqlite(PATH_PREFIX + "/factulator.db")

# first, go through all the existing podcasts and check they're still live
podcasts = DB[:podcasts].filter(:active => true).all
podcasts.each do |podcast|
  puts "checking if #{podcast[:title]} is still available"
  curl_output = `curl -I "#{podcast[:url]}" `
  if curl_output.match("403 Forbidden")
    DB[:podcasts].filter(:page_url => podcast[:page_url]).update(:active => false)
  end
end

# now, get the latest 20
#
index_page_url = "http://www.factmag.com/category/factmixes/"
puts "Getting latest podcasts"
doc = Nokogiri::HTML(open(index_page_url))

pages = doc.css("a.archiveTitle")
descs = doc.css(".post div div p")

pages.each_with_index do |page, i|
  page_url = URI.encode(page.attr("href"))
  page_doc = Nokogiri::HTML(open(page_url))
  puts "Having a look at #{page_url} for links"
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  if mp3_links.any?
    mp3 = mp3_links.first
    title = mp3.inner_text.strip
    desc = descs[i].inner_text
    url = URI.encode(mp3.attr('href'))
    active = true

    unless DB[:podcasts].where(:url => url).any?
      # only get this if we're downloading a new podcast
      puts "Finding out how big this file is."
      # this is so painfully slow I give up.
      #response = Net::HTTP.get_response(URI.parse(url))
      #file_size = response['content-length']

      curl_output = `curl -I "#{url}"`
      # so: split the curl output into an array, find the Content Length and
      # chuck out everything that's not a number, and store it as an int.
      # sorted.
      if curl_output && !curl_output.match("403 Forbidden") && !curl_output.match("resolve host")
        file_size = curl_output.gsub(/\r/,"").split(/\n/).select {|f| f.match('Content-Length')}.first.gsub(/\D/, "").to_i
      else
        file_size = nil
        active = false
      end

      DB[:podcasts].insert(:title => title, :description => desc, :url => url, :page_url => page_url, :file_size => file_size, :active => active)
    end
  end
end

