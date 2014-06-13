class Youtube < PluginBase

  #TODO: TEST THIS: https://www.youtube.com/watch?v=Qapou-3-fM8&list=PL_Z529zmzNGcOVBJA0MgjjQoKiBcmMQWh

  # this will be called by the main app to check whether this plugin is responsible for the url passed
  def self.matches_provider?(url)
    url.include?("youtube.com") || url.include?("youtu.be")
  end

  def initialize
    @cipher_io      = CipherIO.new(self)
    coordinator     = DecipherCoordinator.new(Decipherer.new(@cipher_io), CipherGuesser.new, self)
    @video_resolver = VideoResolver.new(coordinator)
    @url_resolver   = UrlResolver.new(self)
    @format_picker  = FormatPicker.new(self)
  end

  def get_urls_and_filenames(url, options = {})
    urls   = @url_resolver.get_all_urls(url, options[:filter])
    videos = get_videos(urls)

    return_value = videos.map do |video|
      format = @format_picker.pick_format(video, options)
      make_url_filname_hash(video, format)
    end

    return_value.empty? ? download_error("No videos could be downloaded.") : return_value
  end

  def notify(message)
    puts "[YOUTUBE] #{message}"
  end

  private

  def download_error(message)
    raise CouldNotDownloadVideoError, message
  end

  def get_videos(urls)
    videos = urls.map do |url|
      begin
        @video_resolver.get_video(url)
      rescue VideoResolver::VideoRemovedError
        notify "The video #{url} has been removed."
        nil
      rescue => e
        notify "Error getting the video: #{e.message}"
        nil
      end
    end
    videos.reject(&:nil?)
  end

  def make_url_filname_hash(video, format)
    url = video.get_download_url(format.itag)
    {
      url: url,
      name: video.title,
      ext: ".#{format.extension}",
      extra: format_extra(video),
      on_downloaded: make_downloaded_callback(video)
    }
  end

  def format_extra(video)
    video.url_data.map do |data|
      format = FormatPicker::FORMATS.find { |format| format.itag == data[:itag].to_s }
      {format: format, url: data[:url]}
    end
  end

  def make_downloaded_callback(video)
    return nil unless video.signature_guess?

    lambda do |success|
      @cipher_io.add_cipher(video.cipher_version, video.cipher_operations) if success
    end
  end
end
