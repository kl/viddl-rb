require 'open-uri'
require 'json'

class Bandcamp < PluginBase
  
  # this will be called by the main app to check whether this plugin is responsible for the url passed
  def self.matches_provider?(url)
    url.include?("bandcamp.com")
  end


  # return the url for original video file and title
  def get_urls_and_filenames(url, options = {})
    # locate the js object with all the tracks data
    url_and_files = []
    doc           = Nokogiri::HTML(open(get_http_url(url)))
    js            = doc.at("script:contains('var TralbumData')").text
    match         = js[/trackinfo.*(\[.*\])/,1]

    # parse the js object
    JSON.parse(match).each do |track_data|

      # hopefully the last is the best
      track_url = track_data["file"].values.last
      
      track_name = track_data['title']
      
      # add to the response
      url_and_files << {url: track_url, name: track_name, ext: ".mp3"}
    end

    url_and_files
  end
  
  def get_http_url(url)
    url.sub(/https?:\/\//, "http:\/\/")
  end
end
