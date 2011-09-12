require 'rubygems'
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'sequel'

PATH_PREFIX = File.expand_path(File.dirname(__FILE__))

DB = Sequel.sqlite(PATH_PREFIX + "/factulator.db")

# first, go through all the existing podcasts and check they're still live
podcasts = DB[:podcasts].all
podcasts.each do |podcast|
  doc = Nokogiri::HTML(open(podcast.page_url))
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  unless mp3_links.any?
    DB[:podcasts].filter(:page_url => podcast.page_url).update(:active => false)
  end
end

# now, get the latest 20
#
index_page_url = "http://www.factmag.com/category/factmixes/"

doc = Nokogiri::HTML(open(index_page_url))

pages = doc.css("a.archiveTitle")
descs = doc.css(".post div div p")

pages.each_with_index do |page, i|
  page_url = URI.encode(page.attr("href"))
  page_doc = Nokogiri::HTML(open(page_url))
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  if mp3_links.any?
    mp3 = mp3_links.first
    title = mp3.inner_text.strip
    desc = descs[i]
    url = URI.encode(mp3.attr('href'))

    unless DB[:podcasts].where(:url => url).any?
      # only get this if we're downloading a new podcast
      response = Net::HTTP.get_response(URI.parse(url))
      file_size = response['content-length']

      DB[:podcasts].insert(:title => title, :description => desc, :url => url, :page_url => page_url, :file_size => file_size)
    end
  end
end

