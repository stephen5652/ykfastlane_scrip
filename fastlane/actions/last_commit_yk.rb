require 'fastlane/action'

module Fastlane
  module Actions
    class LastCommitYkAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:

        work_path = params[:work_path]
        result = nil
        Dir.chdir(work_path) do
          result = Actions.last_git_commit_dict
          branch_name = Actions.git_branch
          result[:branch] = branch_name unless branch_name.blank?
        end
        # sh "shellcommand ./path"
        result
        # Actions.lane_context[SharedValues::LAST_COMMIT_YK_CUSTOM_VALUE] = "my_val"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'A short description with <= 80 characters of what this action does'
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        'You can use this action to do cool things...'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :work_path,
                                       description: '工程目录绝对路径', # a short description of this parameter
                                       default_value: false,
                                       verify_block: proc do |value|
                                         unless value and !value.empty?
                                           UI.user_error!("No work_path for LastCommitYkAction given, pass using `work_path: 'path'`")
                                         end
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end)
        ]
      end

      def self.return_value
        'Returns the following dict: {commit_hash: "commit hash", abbreviated_commit_hash: "abbreviated commit hash" author: "Author", author_email: "author email", message: "commit message"}'
      end

      def self.return_type
        :hash_of_strings
      end

      def self.sample_return_value
        {
          message: 'message',
          author: 'author',
          author_email: 'author_email',
          commit_hash: 'commit_hash',
          abbreviated_commit_hash: 'short_hash',
          branch_name: 'master or null'
        }
      end

      def self.example_code
        [
          'commit = last_commit_yk(work_path: "~/a/b/c")
          pilot(changelog: commit[:message]) # message of commit
          author = commit[:author] # author of the commit
          author_email = commit[:author_email] # email of the author of the commit
          hash = commit[:commit_hash] # long sha of commit
          branch_name = commit[:branch_name] # branch name maybe null, once git is at tag or commit_id
          short_hash = commit[:abbreviated_commit_hash] # short sha of commit'
        ]
      end

      def self.category
        :source_control
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['stephen5652@126.com/stephenchen']
      end

      def self.is_supported?(platform)
        # you can do things like
        #
        #  true
        #
        #  platform == :ios
        #
        #  [:ios, :mac].include?(platform)
        #

        platform == :ios
      end
    end
  end
end
