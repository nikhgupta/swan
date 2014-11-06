module Swan
  class CLI < Thor::Group

    desc "Download data from a given URL."
    argument :url, type: :string, desc: "URL to download the data from."
    class_option :threads, type: :numeric, default: 4, desc: "number of threads to use."
    class_option :what, type: :string, default: "data", desc: "what should be downloaded?"
    class_option :downloads_path, type: :string, default: ENV['HOME']

    def download
      Swan.say :info, "Downloading to: #{options[:downloads_path]}"
      Swan.say :info, "Downloading #{options[:what]} from #{url}"
      strategy = Swan::Strategy.find_for url

      meths = strategy.available_downloads

      if meths.count < 2 || (options[:what] && meths.include?(options[:what].underscore.to_sym))
        what = meths[0] || options[:what].underscore.to_sym
        strategy.new what, url, File.join(options[:downloads_path])
      else
        Swan.say :failed, "This strategy provides multiple download options."
        Swan.say :info, "Please, specify what you want to download via --what parameter."

        meths.unshift "Available:"
        Swan.say :info, meths.join("\n" + (" " * 14) + "- ")
        exit 1
      end
    rescue Interrupt
      puts
      Swan.say :good_bye, nil, :cyan
    rescue RuntimeError => e
      Swan.say :error, e.message
      Swan.say :backtrace, e.backtrace.join("\n" + " " * 14) if ENV['DEBUG']
    end
  end
end
