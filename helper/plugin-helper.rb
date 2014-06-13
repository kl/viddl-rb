module ViddlRb

  class PluginBase

    # This exception is raised by the plugins when it was not 
    # possible to download the video for some reason.
    class CouldNotDownloadVideoError < StandardError; end

    class << self

      attr_reader :registered_plugins

      # If you inherit from this class, the child gets added to the "registered plugins" array.
      def inherited(child)
        @registered_plugins ||= []
        @registered_plugins << child
      end

      def get_plugin(url, io = $stdout)
        plugin_class = registered_plugins.find { |pc| pc.matches_provider?(url) }
        plugin_class ? new_plugin(plugin_class, io) : nil
      end

      def get_all_plugins(io = $stdout)
        registered_plugins.map { |plugin_class| new_plugin(plugin_class, io) }
      end

      # Returns an instance of plugin_class with the given IO object.
      # The IO object is assigned before the plugin's initialize method is executed.
      def new_plugin(plugin_class, io)
        plugin = plugin_class.allocate
        plugin.io = io
        plugin.send(:initialize)
        plugin
      end
    end

    attr_accessor :io

    # Delegates calls to matches_provider? that are made on a plugin instance to the
    # class method matches_providers?. This is used by the library.
    def matches_provider?(url)
      self.class.matches_provider?(url)
    end

    # The following methods redirects the Kernel printing methods (except #p)
    # to the @io object. This is because sometimes we want plugins write to
    # something else than $stdout. These methods are delegated when they are called
    # from plugin instance methods, not from plugin class methods.

    def puts(*objects)
      @io.puts(*objects)
      nil
    end

    def print(*objects)
      @io.print(*objects)
      nil
    end

    def putc(int)
      @io.putc(int)
      nil
    end

    def printf(string, *objects)
      if string.is_a?(IO) || string.is_a?(StringIO)
        super(string, *objects)  # so we don't redirect the printf that prints to a separate IO object
      else
        @io.printf(string, *objects)
      end
      nil
    end

  end
end
