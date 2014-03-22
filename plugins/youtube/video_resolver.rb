
class VideoResolver

  class VideoRemovedError < StandardError; end

  CORRECT_SIGNATURE_LENGTH = 81
  SIGNATURE_URL_PARAMETER = "signature"

  def initialize(decipherer)
    @decipherer = decipherer
  end

  def get_video(url)
    @json = load_json(url)

    video_data = parse_stream_map(get_stream_map)
    apply_signatures!(video_data)

    Video.new(get_title, video_data)
  end

  private

  def load_json(url)
    html = open(url).read
    json_data = html[/ytplayer\.config\s*=\s*(\{.+?\});/m, 1] 
    MultiJson.load(json_data)
  end

  def get_stream_map
    stream_map = @json["args"]["url_encoded_fmt_stream_map"]
    raise VideoRemovedError.new if stream_map.nil? || stream_map.include?("been+removed")
    stream_map
  end

  def get_html5player_version
    @json["assets"]["js"][/html5player-(.+?)\.js/, 1]
  end

  def get_title
    @json["args"]["title"]
  end

  #
  # Returns a an array of hashes in the following format:
  # [
  #  {format: format_id, url: download_url},
  #  {format: format_id, url: download_url}
  #  ...
  # ]
  #
  def parse_stream_map(stream_map)
    entries = stream_map.split(",")

    parsed = entries.map { |entry| parse_stream_map_entry(entry) }
    #parsed.each { |entry| apply_signature!(entry) if entry[:sig] }
    parsed
  end

  def parse_stream_map_entry(entry)
    # Note: CGI.parse puts each value in an array.
    params = CGI.parse((entry))

    {
      itag: params["itag"].first,
      sig:  fetch_signature(params),
      url:  url_decode(params["url"].first)
    }
  end

  # The signature key can be either "sig" or "s".
  # Very rarely there is no "s" or "sig" paramater. In this case the signature is already
  # applied and the the video can be downloaded directly.
  def fetch_signature(params)
    sig = params.fetch("sig", nil) || params.fetch("s", nil)
    sig && sig.first
  end

  def url_decode(text)
    while text != (decoded = CGI::unescape(text)) do
      text = decoded
    end
    text
  end

  def apply_signatures!(video_data)

    video_data.each do |entry|
      next unless entry[:sig]

      sig, is_guess  = @decipherer.decipher(entry[:sig], get_html5player_version)
      entry[:url]    << "&#{SIGNATURE_URL_PARAMETER}=#{sig}"
      entry[:guess?] = is_guess
      entry.delete(:sig)
    end
  end


  class Video
    attr_reader :title

    def initialize(title, video_data)
      @title = title
      @video_data = video_data
    end

    def available_itags
      @video_data.map { |entry| entry[:itag] }
    end

    def get_download_url(itag)
      entry = @video_data.find { |entry| entry[:itag] == itag }
      entry[:url] if entry
    end

    def signature_guess?
      @video_data.first[:guess?]
    end
  end
end
