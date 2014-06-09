require "pry"
require 'taglib'
require 'mechanize'
require 'active_support/inflector'

require "swan/version"
require "swan/strategy"

module Swan

  def self.agent
    @agent ||= Mechanize.new{ |a| a.user_agent_alias = 'Mac Safari' }
  end

  def self.downloader url, path, options = {}
    command  = "wget -ct 3 \"#{url}\" -O \"#{path}\""
    command += " --referer=#{options.fetch(:referer)}" if options.fetch(:referer)
    say options.fetch(:status), options.fetch(:message), options.fetch(:color, :magenta) if options.fetch(:status)
    if ENV['DEBUG']
      say :run, command
      system command
    else
      system "#{command} --quiet"
    end
    path
  end

  def self.say status, message, color = nil
    color ||= case status.to_s.downcase
              when "info", "found" then :cyan
              when "success", /^pass/ then :green
              when /^warn/, "backtrace" then :yellow
              when /^fail/, "error" then :red
              when "run", "fetch", "download" then :magenta
              else :white
              end
    @shell ||= Thor::Shell::Color.new
    @shell.say_status status.to_s.titleize, message, color
  end
end
