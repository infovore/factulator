require 'rubygems'
require 'nokogiri'
require 'open-uri'

index_page_url = "http://www.factmag.com/category/factmixes/"

doc = Nokogiri::HTML(open(index_page_url))

pages = doc.css("a.archiveTitle")

mp3s = []

pages.each do |page|
  page_url = page.attr("href")
  page_doc = Nokogiri::HTML(open(page_url))
  mp3_links = page_doc.css("a").select {|link| link.attr("href").match("mp3.factmagazine.co.uk")}
  if mp3_links.any?
    mp3 = mp3_links.first
    mp3s << {:title => mp3.inner_text, :url => mp3.attr("href"), :page_url => page_url}
  end
end

p mp3s
