class Veoh < PluginBase
  VEOH_API_BASE = "http://www.veoh.com/api/"
  PREFERRED_FORMATS = [:mp4, :flash] # mp4 is preferred because it enables downloading full videos and not just previews
  
  #this will be called by the main app to check whether this plugin is responsible for the url passed
  def self.matches_provider?(url)
    url.include?("veoh.com")
  end

  def get_urls_and_filenames(url, options = {})
    veoh_id = url[/\/watch\/([\w\d]+)/, 1]
    info_url = "#{VEOH_API_BASE}findByPermalink?permalink=#{veoh_id}"
    info_doc = Nokogiri::XML(open(info_url))

    download_url = get_download_url(info_doc)
    extension = download_url[/\/[\w\d]+(\.[\w\d]+)\?ct/, 1]
    file_name = info_doc.xpath('//rsp/videoList/video').first.attributes['title'].content

    [{url: download_url, :name => file_name, ext: extension}]
  end
  
  #returns the first valid download url string, in order of the prefered formats, that is found for the video
  def get_download_url(info_doc)
    PREFERRED_FORMATS.each do |format|
      a = get_attribute(format)
      download_attr = info_doc.xpath('//rsp/videoList/video').first.attributes[a]
      return(download_attr.content) unless download_attr.nil? || download_attr.content.empty?
    end
  end
  
  def get_attribute(format)
    case format
    when :mp4
      "ipodUrl"
    when :flash
      "previewUrl"
    end
  end
end
