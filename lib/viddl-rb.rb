#!/usr/bin/env ruby
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'helper')

require "rubygems"
require "net/http"
require "nokogiri"
require "multi_json"
require "cgi"
require "open-uri"
require "open3"
require "stringio"
require "download-helper.rb"
require "plugin-helper.rb"
require "utility-helper.rb"
require "audio-helper.rb"

ViddlRb::UtilityHelper.load_plugin_classes

module ViddlRb

  class DownloadError < StandardError; end

  module LibraryExceptionHelpers

    def download_error(error, additional_message = "")

      if error.is_a?(Exception)
        download_error = DownloadError.new(error.message + additional_message)
        download_error.set_backtrace(error.backtrace)
        raise download_error
      else
        raise DownloadError.new(error.to_s + additional_message)
      end
    end
  end

  extend LibraryExceptionHelpers

  def self.download(url, filename, options = {})
    opts = {
      save_dir: ".",
      retries: 0,
      extract_audio: false
      }.merge(options)

    success = DownloadHelper.save_file(url, filename, opts)
    download_error "Error downloading file: #{url}" unless success

    begin
      AudioHelper.extract(filename, opts[:save_dir]) if opts[:extract_audio]
    rescue StandardError => e
      download_error(e)
    end
  end

  class Agent

    include LibraryExceptionHelpers

    attr_accessor :plugin_io

    def initialize(io = nil)
      @io = io
    end
      
    def get(url, options = {})
      get_playlist(url, options).first
    end

    def get_playlist(url, options = {})
      plugin  = find_plugin(url)
      options = format_options(options)

      data   = run_plugin(plugin, url, options) 
      output = read_plugin_output(plugin)

      @io.write(output) if @io && !output.empty?

      get_videos(data, output)
    end

    private

    def find_plugin(url)
      plugin = PluginBase.get_plugin(url) 
      download_error "No plugin found for URL '#{url}'" unless plugin
      plugin.io = StringIO.new
      plugin
    end

    def format_options(opts)
      # Put the video quality values inside a new hash called :quality
      opts[:quality] = {width:  opts.delete(:width),
                        heigth: opts.delete(:height),
                        ext:    opts.delete(:format)}

      # Put the filter regex in the internally used format
      filter = opts[:filter]
      opts[:filter] = {regex: filter, reject: false} if filter.is_a?(Regexp)

      opts
    end

    def run_plugin(plugin, url, options)
      plugin.get_urls_and_filenames(url, options)
    rescue PluginBase::CouldNotDownloadVideoError => e
      download_error(e)
    rescue StandardError => e
      download_error(e, " [Plugin: #{plugin.class}")
    end

    def read_plugin_output(plugin)
      plugin.io.rewind
      plugin.io.read
    end

    def get_videos(plugin_data, output)
      plugin_data.map do |entry|
        entry[:filesafe_name] = UtilityHelper.make_filename_safe(entry[:name] + entry[:ext])
        entry[:output] = output
        Video.new(entry)
      end
    end

  end

  class Video

    attr_reader :url, :name, :filesafe_name, :ext, :output, :extra 

    def initialize(args)
      @url, @name, @filesafe_name, @ext, @output, @extra = 
        args[:url], args[:name], args[:filesafe_name], args[:ext], args[:output], args[:extra]
    end

    def download(options = {})
      filename = options.fetch(:filename, filesafe_name)
      ViddlRb.download(url, filename, options)
    end

  end
end
