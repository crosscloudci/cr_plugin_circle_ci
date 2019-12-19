require "./concerns/*"
require "halite"
require "debug"
require "poncho"

# https://travis-ci.org/linkerd/linkerd2/builds/315084566
class CrPluginCircleCi::CLI::Commands::CircleCi < Admiral::Command
	include CIAuth
	define_help description: "Specifies the CircleCI registry for your project"

	define_flag project : String,
		description: "The name of the project in the repository, e.g. crosscloud/test_proj",
		long: project,
		short: p,
		required: true

	define_flag ref : String,
		description: "The commit ref of the project build that is of interest, e.g. 834f6f1 or a1724ce5e0c59bef272723f328e675980ddc90ea",
		long: commit,
		short: c,
		required: true

	@all_builds = Array(Hash(String, JSON::Any)).new
	@returned_build_status = String.new
	@returned_build_url = String.new
	def run 
		client = init_circle_http_client
		done = false 
		paginated_limit = 100
		paginated_offset = 0 
		loop do 
			poncho = Poncho.from_file "./.env"
			# r = client.get("/api/v1.1/project/#{poncho["VCS_TYPE"]}/#{poncho["USER_NAME"]}/#{URI.encode_www_form(flags.project)}?circle-token=#{poncho["CIRCLECI_API_KEY"]}&limit=100&filter=successful&shallow=true")
			r = client.get("/api/v1.1/project/github/#{URI.encode_www_form(flags.project)}?circle-token=&limit=#{paginated_limit}&offset=#{paginated_offset}&shallow=true")
			begin
				r.raise_for_status
				response_body = JSON.parse(r.body)
        break if response_body.as_a.size == 0 
				builds = collect_builds(response_body)
       
				builds.each do |build|
          if build["vcs_revision"].as_s[0..6] == flags.ref[0..6]
						@returned_build_status = build["status"].as_s
						@returned_build_url = build["build_url"].as_s
						done = true
					end
				end 
				paginated_limit = 100
        paginated_offset = @all_builds.size
			# rescue ex : Halite::ClientError | Halite::ServerError
			# 	p "[#{ex.status_code}] #{ex.status_message} (#{ex.class})"
			end
			break if done == true 
		end 	
    case @returned_build_status 
    when "scheduled"
      @returned_build_status = "running"
    when "running"
      @returned_build_status = "running"
    when "retried"
      @returned_build_status = "running"
    when "queued"
      @returned_build_status = "running"
    when "fixed"
      @returned_build_status = "success"
    when "no_tests"
      @returned_build_status = "success"
    when "success"
      @returned_build_status = "success"
    when "canceled"
      @returned_build_status = "failed"
    when "infrastructure_fail"
      @returned_build_status = "failed"
    when "timedout"
      @returned_build_status = "failed"
    when "failed"
      @returned_build_status = "failed"
    when "not_run"
      @returned_build_status = "failed"
    when "not_running"
      @returned_build_status = "failed"
    else 
      @returned_build_status = "not_found"
    end 
    if @returned_build_status == "not_found"
      puts "ERROR: failed to find project with given commit"
    else 
      puts "status\tbuild_url\n"
      puts "#{@returned_build_status}\t#{@returned_build_url}"
    end 
  end 

  def collect_builds(response_body)
    loop do 
      response_body_size = response_body.size
      build_count = 0
      break if response_body_size == 0  
      response_body.as_a.each do |build|
        build_count += 1 
        @all_builds.push(build.as_h)
      end
      break if response_body_size == build_count
    end
    return @all_builds
  end
end
