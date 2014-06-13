# Downloader iterates over a download queue and downloads and saves each video in the queue.
class Downloader
  class DownloadFailedError < StandardError; end

  def download(download_queue, params)
    download_queue.each do |video_data|
      # Skip invalid invalid link
      next unless video_data

      url = video_data[:url]
      name = ViddlRb::UtilityHelper.make_filename_safe(video_data[:name]) + video_data[:ext]

      result = ViddlRb::DownloadHelper.save_file url,
                                                 name,
                                                 :save_dir => params[:save_dir],
                                                 :tool => params[:tool] && params[:tool].to_sym
      if result
        puts "Download for #{name} successful."
        video_data[:on_downloaded].call(true) if video_data[:on_downloaded]
        ViddlRb::AudioHelper.extract(name, params[:save_dir]) if params[:extract_audio]
      else
        video_data[:on_downloaded].call(false) if video_data[:on_downloaded]
        if params[:abort_on_failure]
          raise DownloadFailedError, "Download for #{name} failed."
        else
          puts "Download for #{name} failed. Moving onto next file."
        end
      end
    end
  end
end
