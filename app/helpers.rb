require 'nokogiri'

module Helpers
  def unmention(post)
    df = Nokogiri::HTML.fragment(post)
    first_mention = df.css('[itemprop=mention]').first
    first_mention.unlink unless first_mention.nil?
    first_hashtag = df.css('[itemprop=hashtag]').first
    first_hashtag.unlink unless first_hashtag.nil?
    df.to_html
  end

  def dateformat(datestr)
    Time.parse(datestr).strftime '%B %d, %Y %R'
  end

  def active_filter?(type)
    params[:filter] == type.downcase
  end

  def types
    [
      {:slug => 'ideas',  :singular => 'Idea',   :plural => 'Ideas',  :icon => 'icon-bullhorn'},
      {:slug => 'bugs',   :singular => 'Bug',    :plural => 'Bugs',   :icon => 'icon-fire'},
      {:slug => 'praise', :singular => 'Praise', :plural => 'Praise', :icon => 'icon-heart'},
    ]
  end

  def type_of_entry(entry)
    anns = entry['annotations'].select { |a| a['type'] == 'com.floatboth.supportadn.entry' }
    types.select { |t| t[:slug] == anns.first['value']['type'] }.first unless anns.empty?
  end

  def get_last_form
    form = session[:form] || {}
    session[:form] = nil
    form
  end

  def id_to_name(id)
    @adn.get("users/#{id}").body['data']['username']
  end
end
