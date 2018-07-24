require "utils/github"

module GitHub
  module_function

  ORG_READ_ACCESS_SCOPES = ["read:org"].freeze

  def members(org, team: nil)
    if team
      url = "#{API_URL}/orgs/#{org}/teams"
      teams = open_api(url, scopes: ORG_READ_ACCESS_SCOPES)

      team = teams.detect { |t| t["name"] == team }

      return [] unless team
      open_api("#{team["url"]}/members", scopes: ORG_READ_ACCESS_SCOPES)
    else
      url = "#{API_URL}/orgs/#{org}/members"
      scopes = CREATE_ISSUE_FORK_OR_PR_SCOPES
      open_api(url, scopes: scopes)
    end
  end
end

module Hbc
  class CLI
    class Ci < AbstractCommand
      def run
        committer, = ENV["TRAVIS_PULL_REQUEST_SLUG"]&.split("/", 2)

        maintainer_pr = begin
          maintainers = begin
            GitHub.members("Homebrew", team: "cask").map { |member|
              puts member

               member["login"] }
          rescue GitHub::AuthenticationFailedError
            []
          end



          maintainers.include?(committer)
        end

        puts "Comitter: #{committer}"
        puts "Maintainer PR: #{maintainer_pr}"
      rescue => e
        raise e.message
      end
    end
  end
end
