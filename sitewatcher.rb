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
require 'ostruct'

### Constants ##################################################################
## Execution types.
EXEC_TYPE_LOOKUP  = 0
EXEC_TYPE_INSTANT = 1
################################################################################

### Global Variables ###########################################################
$store = PStore.new("sitewatcher.pstore")
$options = OpenStruct.new
################################################################################

### Functions ##################################################################
def get_source_contents(url)
	string = ""
	open(url, "Cache-Control"=>"no-cache") do |file|
		file.each_line {|line| string << line}
	end
	return string
end

def persistant_source_changed?(domain, location = '/')
	source = get_source_contents(domain+location)
	
	hashed = source		# TODO: Hash using predictable hash function.
	
	$store.transaction do
		current = $store[domain + location]
		if current == nil
			$store[domain + location] = hashed
			return 'New value stored.'
		elsif hashed == current
			return false;
		else
			$store[domain + location] = hashed
			return true;
		end
	end
end

def instant_watch(domain, location = '/')
	init_source = get_source_contents(domain+location)
	source = String.new(init_source)
	
	count = 0
	
	while init_source == source and count < $options.request_limit
		sleep $options.wait_time
		
		source = get_source_contents(domain+location)
		
		if init_source == source
			puts "No change at #{domain+location}"
		end
		count+=1
	end
	
	if init_source != source
		puts "Changed!"
	else
		puts "No change found before request limit reached."
	end
end
################################################################################

### Option Handling ############################################################
## Default options.
$options.exec_type = EXEC_TYPE_INSTANT
$options.wait_time = 2
$options.request_limit = 10000000
$options.source = "http://www.reddit.com"	# TODO: Must be better way?

OptionParser.new do |opts|
	opts.banner = "Usage: sitewatcher.rb -s <site> [options]"
	
	## Options parsing.
	opts.on("-h", "--help",
	 "Show help message.") do |v|
		puts opts
		exit()
	end
	
	opts.on("-s", "--source <s>", String,
	 "Set source location") do |s|
		$options.source = s
	end
	
	opts.on("-t", "--wait-time <t>", Integer,
	 "Number of seconds to wait between requests") do |t|
		$options.wait_time = t
	end
	
	opts.on("-p", "--persistence-check",
	 "Check if source changed from cache") do
		$options.exec_type = EXEC_TYPE_LOOKUP
	end
	
	opts.on("-l", "--limit-requests <l>", Integer,
	 "Limit number of checks performed") do |l|
		$options.request_limit = l
	end
end.parse!
################################################################################

### If this file executed ######################################################
if __FILE__ == $0
	if EXEC_TYPE_INSTANT == $options.exec_type
		instant_watch($options.source)
	else
		result = persistant_source_changed?($options.source)
		if true == result
			puts "Changed!"
		elsif false == result
			puts "Not changed."
		else
			puts result
		end
	end
end
################################################################################
