require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sequel'

DB = Sequel.sqlite('factulator.db')

index_page_url = "http://www.factmag.com/category/factmixes/"

doc = Nokogiri::HTML(open(index_page_url))

pages = doc.css("a.archiveTitle")

pages.each do |page|
  page_url = page.attr("href")
  page_doc = Nokogiri::HTML(open(page_url))
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  if mp3_links.any?
    mp3 = mp3_links.first
    title = mp3.inner_text
    url = mp3.attr('href')

    unless DB[:podcasts].where(:url => url).any?
      DB[:podcasts].insert(:title => title, :url => url, :page_url => page_url)
    end
  end
end

