require 'rubygems'
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'sequel'

DB = Sequel.sqlite('factulator.db')

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

pages.each do |page|
  page_url = URI.encode(page.attr("href"))
  page_doc = Nokogiri::HTML(open(page_url))
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  if mp3_links.any?
    mp3 = mp3_links.first
    title = mp3.inner_text.strip
    url = URI.encode(mp3.attr('href'))

    response = Net::HTTP.get_response(URI.parse(url))
    file_size = response['content-length']

    unless DB[:podcasts].where(:url => url).any?
      DB[:podcasts].insert(:title => title, :url => url, :page_url => page_url, :file_size => file_size)
    end
  end
end

