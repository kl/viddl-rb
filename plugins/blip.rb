class Blip < PluginBase
  # this will be called by the main app to check whether this plugin is responsible for the url passed
  def self.matches_provider?(url)
    url.include?("blip.tv")
  end

  # return the url for original video file and title
  def get_urls_and_filenames(url, options = {})
    id           = to_id(url)
    xml_url      = "http://blip.tv/rss/#{id}"
    doc          = Nokogiri::XML(open(xml_url))
    user         = doc.at("//channel/item/blip:user").inner_text
    title        = doc.at("//channel/item/title").inner_text
    download_url = doc.at("//channel/item/media:group/media:content").attributes["url"].value
    final_url    = UtilityHelper.get_final_location(download_url)
    extention    = download_url.split(".").last
    file_name    = "#{id}-#{user}-#{title}"

    [{url: final_url, name: file_name, ext: "." + extention}]
  end

  # usually id is last 7 digits
  def to_id(url)
    URI::split(url)[5].split("/")[2].split("-").last
  end
end
