class NewsItem < ActiveRecord::Base
  has_many :comments
  
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
          item.published = raw_item.elements['dc:date'].text.gsub(/[TZ]/, ' ')
          item.active = true
          item.save
          active << item
        end
        NewsItem.update_all("active = 0", "id not in (#{active.map { |n| n.id }.join(',')})")
      end
    end  
    
    def get_feed_items
      if NEWS_RSS_URL
        xml = Net::HTTP.get(URI.parse(NEWS_RSS_URL))
        root = REXML::Document.new(xml).root
        root.elements.to_a('item')
      end
    end
  end
end