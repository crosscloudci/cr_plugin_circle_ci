require "halite"
require "poncho"
module CrPluginCircleCi::CLI::Commands::CIAuth
	def init_circle_http_client
		# ci_auth = retrieve_ci_api_auth
		client = Halite::Client.new do
			# Set basic auth
			# basic_auth "#{ci_auth["key"]}", ""
			# Enable logging
		  logging false
			timeout 10.seconds
			headers "Accept": "application/json"
			endpoint "https://circleci.com/"
		end
	end

	def retrieve_ci_api_auth
		ci_auth = {} of String => String 
		begin
			poncho = Poncho.from_file "./.env"
			ci_auth["key"] = poncho["CIRCLECI_API_KEY"]
		rescue e
			puts "Please add your .env file to handle authentication: #{e.message}"
		end
		return ci_auth 
	end 
end 
