# == Schema Information
#
# Table name: news_items
#
#  id        :integer       not null, primary key
#  title     :string(255)   
#  link      :string(255)   
#  body      :text          
#  published :datetime      
#  active    :boolean       default(TRUE)
#  site_id   :integer       
#

class NewsItem < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  belongs_to :site
  
  scope_by_site_id
  
  def name; title; end
  def created_at; published; end
  
  class << self
    def update_from_feed
      if raw_items = get_feed_items
        active = []
        raw_items.each do |raw_item|
          item = NewsItem.find_by_link(raw_item.elements['link'].text) || NewsItem.new
          item.link = raw_item.elements['link'].text
          item.title = raw_item.elements['title'].text
          item.body = raw_item.elements['description'].text
          item.published = (raw_item.elements['dc:date'] || raw_item.elements['pubDate']).text.gsub(/[TZ]/, ' ') rescue nil
          item.active = true
          item.save
          active << item
        end
        NewsItem.update_all("active = 0", "id not in (#{active.map { |n| n.id }.join(',')})") if active.any?
      end
    end  
    
    def get_feed_items
      if Setting.get(:url, :news_rss)
        begin
          xml = Net::HTTP.get(URI.parse(Setting.get(:url, :news_rss)))
          root = REXML::Document.new(xml).root
          items = root.elements.to_a('item')
          items.any? ? items : root.elements['channel'].elements.to_a('item')
        rescue
          nil
        end
      end
    end
  end
end
