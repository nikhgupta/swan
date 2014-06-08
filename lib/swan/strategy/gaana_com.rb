module Swan
  module Strategy
    class GaanaCom
      class Song
        attr_accessor :id, :name, :album, :artist, :popularity, :image, :thumb, :referer

        class << self
          def from_partial partial, page, downloads_path
            id = partial.search(".playcol").attr("data-value").text.strip.to_i rescue 0
            return unless id > 0

            info   = partial.search(".songcol .sngandalbum")
            name   = info.search("[data-type='playSong']").text.strip
            album  = info.search("a._album").text.strip rescue nil
            not_on_own_page = true if album && !album.empty?

            album  = page.search(".play_list h1.heading").text.strip if album.empty?
            artist = partial.search(".artistcol").text.strip
            popularity = partial.search(".popular_len").attr("style").text.match(/width:(\d*)px/)[1].to_i rescue 0

            album_page = not_on_own_page ? Swan.agent.get(info.search("a._album")[0]["href"]) : page
            thumb = album_page.search("#mainarea .play_list img").attr("src").text
            image = thumb.gsub("_175x175_", "_480x480_")

            self.new id: id, name: name, album: album, artist: artist, thumb: thumb,
              popularity: popularity, image: image, downloads_path: downloads_path,
              referer: page.uri
          end
        end

        def initialize options = {}
          @downloads_path = options.delete(:downloads_path) || ENV['HOME']
          options.each { |key, val| self.send("#{key}=", val) }
        end

        def fullname
          "[#{album}] #{name}"
        end

        def album_dir
          File.join(@downloads_path, "Music", "Gaana.com", album)
        end

        def file_path
          FileUtils.mkdir_p(album_dir) unless File.directory?(album_dir)
          File.join album_dir, "#{name}.mp3"
        end

        def art_path
          File.join album_dir, "album-art.jpg"
        end

        def stream_url
          url = "http://gaana.com/streamprovider/get_stream_data_v1.php?track_id=#{id}"
          JSON.parse(Swan.agent.get(url).body)["stream_path"] rescue nil
        end

        def perform_download
          raise "No download url found for: #{fullname}." unless stream_url

          Swan.downloader image, art_path, status: "Artwork", message: album, referer: referer unless File.size?(art_path)
          Swan.downloader thumb, art_path, status: "Artwork", message: album, referer: referer unless File.size?(art_path)
          Swan.downloader stream_url, file_path, status: "Song", message: fullname, referer: referer
        end

        def add_id3v2_tags
          Swan.say :id3v2, fullname, :yellow if ENV["DEBUG"]

          TagLib::MPEG::File.open(file_path) do |file|
            tag = file.id3v2_tag

            tag.title   = name
            tag.album   = album
            tag.artist  = artist
            tag.comment = "Downloaded from Gaana.com"

            apic  = TagLib::ID3v2::AttachedPictureFrame.new
            apic.mime_type = "image/jpeg"
            apic.description = "Cover"
            apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
            apic.picture = File.open(art_path, 'r') { |f| f.read }
            tag.add_frame(apic)

            if popularity > 20
              rate = TagLib::ID3v2::PopularimeterFrame.new
              rate.rating = 5
              tag.add_frame(rate)
            end

            file.save
          end
        end
      end

      def self.hosts
        [ /gaana\.com$/ ]
      end

      def self.available_downloads
        [ :music ]
      end

      attr_accessor :urls, :downloads_path

      def initialize what, url, directory
        self.urls = [ url ]
        self.downloads_path = directory

        send("download_#{what}")
      end

      def download_music
        counter = 0
        @urls.map do |url|
          uri  = URI.parse url
          path = uri.path
          parse_collection_urls url
        end.flatten.each do |url|
          page  = Swan.agent.get(url)
          songs = page.search(".playlist").map do |partial|
              Song.from_partial partial, page, @downloads_path
          end.compact.sort_by{|song| song.album}

          songs.each do |song|
            begin
              song.perform_download
              song.add_id3v2_tags
              counter += 1
            rescue StandardError => e
              Swan.say :error, e.message
              Swan.say :warning, "Song may not have been downloaded: #{fullname}"
              Swan.say :backtrace, e.backtrace.join("\n" + " " * 14) if ENV['DEBUG']
            end
            Swan.say :info, "Downloaded #{counter} songs." if counter % 20 == 0
          end
        end

        Swan.say "=" * 12, "=" * 12
        Swan.say :info, "Downloaded a total of #{counter} songs."
      end

      private

      def parse_collection_urls url
        path = URI.parse(url).path
        return [url] unless path =~ /^\/newrelease/ || path =~ /\/mostpopular\/.*\/album\//
        Swan.agent.get(url).search(".content-container .list .title a").map{|a| a["href"]}
      end
    end
  end
end
