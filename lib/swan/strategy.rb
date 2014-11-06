module Swan
  module Strategy

    def self.all
      pattern = File.join(File.dirname(__FILE__), "strategy", "*.rb")
      Dir.glob(pattern).map{ |file| File.basename(file, ".rb") }
    end

    def self.load_all
      self.all.each do |strategy|
        require File.join(File.dirname(__FILE__), "strategy", "#{strategy}.rb")
      end
    end

    def self.klass_for strategy
      Swan::Strategy.const_get(strategy.camelize)
    end

    def self.find_for url
      url_host = URI.parse(url).host

      self.load_all.each do |strategy|
        klass = self.klass_for(strategy)
        matched = klass.hosts.detect{ |host| url_host =~ host }
        return klass if matched
      end

      raise "Strategy/host not implemented, yet."
    end
  end
end
