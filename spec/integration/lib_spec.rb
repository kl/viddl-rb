#encoding: utf-8

$LOAD_PATH << File.join(File.dirname(__FILE__), '../..', 'lib')

require 'minitest/autorun'
require 'rest_client'
require 'viddl-rb.rb'

class LibTest < Minitest::Test

  def setup
    @agent = ViddlRb::Agent.new
  end

  def test_can_get_single_youtube_video
    video = @agent.get("https://www.youtube.com/watch?v=kCfiKj8Iehk")
    url   = video.url
    name  = video.name

    assert_match /^いいぜメーン/, name               # check that the name is correct
    assert_match /^http/, url                      # check that the string starts with http
    assert_match /\/videoplayback\?/, url          # check that we have the video playback string

    Net::HTTP.get_response(URI(url)) do |res|      # check that the location header is empty
      assert_nil res["location"]
      break                                        # break here because otherwise it will read the body for some reason
    end
  end

  def test_can_get_single_youtube_video_with_specific_quality
    video = @agent.get("http://www.youtube.com/watch?v=73rS-EnhP70", width: 480, height: 360, format: "webm")
    
    # Find the format extra that belongs to the URL that the plugin selected
    extra = video.extra.find { |extra| extra[:url] == video.url }
    format = extra[:format]

    assert_equal 480,    format.resolution.width
    assert_equal 360,    format.resolution.height
    assert_equal "webm", format.extension
  end

  def test_can_get_youtube_playlist
    playlist = @agent.get_playlist("http://www.youtube.com/playlist?list=PL41AAC84379472529", filter: {regex: /Rick/, reject: true})
    assert 3, playlist.size
  end

  def test_raises_error_when_plugin_fails
    assert_raises(ViddlRb::DownloadError) do
      @agent.get("http://www.vimeo.com/thisshouldnotexist991122") # bogus url
    end
  end

  def test_raises_error_when_url_not_recognized
    assert_raises(ViddlRb::DownloadError) { @agent.get("12345") }
    assert_raises(ViddlRb::DownloadError) { @agent.get("http://www.google.com") }
  end
end
