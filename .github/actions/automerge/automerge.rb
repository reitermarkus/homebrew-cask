require "json"

Homebrew.install_gem! "git_diff"
require "git_diff"
require_relative "git_diff_extensions"
using GitDiffExtensions

ENV["GITHUB_ACTION"]     = ENV.delete("HOMEBREW_GITHUB_ACTION")
ENV["GITHUB_ACTOR"]      = ENV.delete("HOMEBREW_GITHUB_ACTOR")
ENV["GITHUB_EVENT_NAME"] = ENV.delete("HOMEBREW_GITHUB_EVENT_NAME")
ENV["GITHUB_EVENT_PATH"] = ENV.delete("HOMEBREW_GITHUB_EVENT_PATH")
ENV["GITHUB_REPOSITORY"] = ENV.delete("HOMEBREW_GITHUB_REPOSITORY")
ENV["GITHUB_SHA"]        = ENV.delete("HOMEBREW_GITHUB_SHA")
ENV["GITHUB_TOKEN"]      = ENV.delete("HOMEBREW_GITHUB_TOKEN")
ENV["GITHUB_WORKFLOW"]   = ENV.delete("HOMEBREW_GITHUB_WORKFLOW")
ENV["GITHUB_WORKSPACE"]  = ENV.delete("HOMEBREW_GITHUB_WORKSPACE")

event = JSON.parse(File.read(ENV.fetch("GITHUB_EVENT_PATH")))

require "utils/github"

module GitHub
  module_function

  def pull_requests(repo, **options)
    url = "#{API_URL}/repos/#{repo}/pulls?#{URI.encode_www_form(options)}"
    open_api(url)
  end

  def merge_pull_request(repo, number:, sha:, merge_method:, commit_message: nil)
    url = "#{API_URL}/repos/#{repo}/pulls/#{number}/merge"
    data = { sha: sha, merge_method: merge_method }
    data[:commit_message] = commit_message if commit_message
    open_api(url, data: data, request_method: :PUT, scopes: CREATE_ISSUE_FORK_OR_PR_SCOPES)
  end

  def open_api(url, data: nil, request_method: nil, scopes: [].freeze)
    # This is a no-op if the user is opting out of using the GitHub API.
    return block_given? ? yield({}) : {} if ENV["HOMEBREW_NO_GITHUB_API"]

    args = ["--header", "application/vnd.github.v3+json", "--write-out", "\n%{http_code}"]

    token, username = api_credentials
    case api_credentials_type
    when :keychain
      args += ["--user", "#{username}:#{token}"]
    when :environment
      args += ["--header", "Authorization: token #{token}"]
    end

    data_tmpfile = nil
    if data
      begin
        data = JSON.generate data
        data_tmpfile = Tempfile.new("github_api_post", HOMEBREW_TEMP)
      rescue JSON::ParserError => e
        raise Error, "Failed to parse JSON request:\n#{e.message}\n#{data}", e.backtrace
      end
    end

    headers_tmpfile = Tempfile.new("github_api_headers", HOMEBREW_TEMP)
    begin
      if data
        data_tmpfile.write data
        data_tmpfile.close
        args += ["--data", "@#{data_tmpfile.path}"]

        if request_method
          args += ["--request", request_method.to_s]
        end
      end

      args += ["--dump-header", headers_tmpfile.path]

      output, errors, status = curl_output("--location", url.to_s, *args)
      output, _, http_code = output.rpartition("\n")
      output, _, http_code = output.rpartition("\n") if http_code == "000"
      headers = headers_tmpfile.read
    ensure
      if data_tmpfile
        data_tmpfile.close
        data_tmpfile.unlink
      end
      headers_tmpfile.close
      headers_tmpfile.unlink
    end

    begin
      if !http_code.start_with?("2") || !status.success?
        raise_api_error(output, errors, http_code, headers, scopes)
      end
      json = JSON.parse output
      if block_given?
        yield json
      else
        json
      end
    rescue JSON::ParserError => e
      raise Error, "Failed to parse JSON response\n#{e.message}", e.backtrace
    end
  end
end


puts "ENV"
puts JSON.pretty_generate(Hash[ENV.to_h.sort_by { |k, | k }])
puts

puts "EVENT:"
puts JSON.pretty_generate(event)
puts

# exit if event.fetch("context") != "continuous-integration/travis-ci/pr"
# exit if event.fetch("state") != "success"

def find_pull_request_for_status(event)
  repo = event.fetch("repository").fetch("full_name")

  event.fetch("branches").each do |branch|
    /https:\/\/api.github.com\/repos\/(?<pr_author>[^\/]+)\// =~ branch.fetch("commit").fetch("url")

    pull_requests = GitHub.pull_requests(
      repo,
      base: "#{event.fetch("repository").fetch("default_branch")}",
      head: "#{pr_author}:#{branch.fetch("name")}",
      state: "open",
      sort: "updated",
      direction: "desc",
    )

    return pull_requests.first if pull_requests.count == 1
  end

  nil
end

def diff_for_pull_request(pr)
  diff_url = pr.fetch("diff_url")

  output, _, status = curl_output("--location", diff_url)

  GitDiff.from_string(output) if status.success?
end

def merge_pull_request(pr)
  repo   = pr.fetch("base").fetch("repo").fetch("full_name")
  number = pr.fetch("number")
  sha    = pr.fetch("head").fetch("sha")

  begin
    tries ||= 0

    GitHub.merge_pull_request(
      repo,
      number: number, sha: sha,
      merge_method: :squash,
      commit_message: "Squashed and auto-merged via `automerge`."
    )
  rescue => e
    $stderr.puts e
    raise if (tries += 1) > 3
    sleep 5
    retry
  end
end

def check_diff(diff)
  diff.single_cask? && diff.only_version_or_checksum?
end

puts "PR:"
pr = find_pull_request_for_status(event)
puts JSON.pretty_generate(pr)
puts

puts "DIFF:"
diff = diff_for_pull_request(pr)
puts diff.files.flat_map(&:hunks).flat_map(&:lines)
puts

puts "CHECK:"
check = check_diff(diff)
puts check
puts

puts "Merging pull request #{pr.fetch("number")}…"
begin
  merge_pull_request(pr)
rescue => e
  exit 78
end
