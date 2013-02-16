#!/usr/bin/env ruby
###	sitewatcher.rb
###	Command line tool for monitoring content changes of a web page locally.
###	
###	Written by Graeme Douglas.
###	
###	Please refer to license.md for licensing information.

require 'pstore'
require 'open-uri'
require 'optparse'

### Functions ##################################################################
def get_page_contents(url)
	string = ""
	open(url, "Cache-Control"=>"no-cache") do |file|
		file.each_line {|line| string << line}
	end
	return string
end

def site_changed?(domain, location = '/')
	# TODO: Make this work with HTTPS.
	source = get_page_contents(domain+location)
	
	hashed = source.hash
	
	store = PStore.new("sitewatcher.pstore")
	
	if hashed == store[domain + location]
		return false;
	else
		return true;
	end
end

def instant_watch(domain, location = '/')
	init_source = get_page_contents(domain+location)
	source = String.new(init_source)
	
	while init_source == source
		sleep 2		# TODO: Make this configurable
		
		source = get_page_contents(domain+location)
		
		if init_source == source
			puts "No change at #{domain+location}"
		end
	end
	puts "Changed!"
end
################################################################################

### Option Handling ############################################################
options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: sitewatcher.rb"
end.parse!
################################################################################

### If this file executed ######################################################
if __FILE__ == $0
	domain = 'http://www.reddit.com'
	
	if ARGV[0] != nil
		domain = ARGV[0]
	end
	instant_watch(domain)
end
################################################################################
