require 'pstore'
require 'net/http'
require 'net/https'
require 'uri'
require 'open-uri'

def get_page_request(domain, location, type='http')
	url = URI.parse(domain+location)
	
	req = nil
	requester = nil
	if type == 'https'
		req = Net::HTTPS::Get.new(url.path)
		requester = Net::HTTPS.new(url.host, url.port)
	else
		req = Net::HTTP::Get.new(url.path)
		requester = Net::HTTP.new(url.host, url.port)
	end
p url.path
p req
p requester
	#req.add_field('Cache-Control', 'no-cache')
	
	return req, requester
end

def handle_response(response)
	if response.code == 200
		return response.body
	else
		die("Response code: #{response.code}")
	end
end

def get_page_contents(url)
	string = ""
	open(url, "Cache-Control"=>"no-cache") do |file|
		file.each_line {|line| string << line}
	end
	return string
end

def site_changed?(domain, location = '/')
	# TODO: Make this work with HTTPS.
	source = Net::HTTP.get(domain, location)
	
	hashed = source.hash
	
	store = PStore.new("sitewatcher.pstore")
	
	if hashed == store[domain + location]
		return false;
	else
		return true;
	end
end

def instant_watch(domain, location = '/')
	#request, requester = get_page_request(domain, location)
	
	#response = requester.request(request)
	#init_source = handle_response(response)
	init_source = get_page_contents(domain+location)
	source = String.new(init_source)
	
	while init_source == source
		sleep 2		# TODO: Make this configurable
		
		#response = requester.request(request)
		#source = handle_response
		source = get_page_contents(domain+location)
		
		if init_source == source
			puts "No change at #{domain+location}"
		end
	end
	puts "Changed!"
end

domain = 'stackoverflow.com'
domain = 'http://www.reddit.com'

instant_watch(domain)
