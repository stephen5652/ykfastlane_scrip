module Fastlane
  module Actions
    module SharedValues
      YK_GIT_CHANGES = :YK_GIT_CHANGES
    end

    class GitChangesYkAction < Action
      def self.run(params)
        puts "WORKING PATH:#{Dir.pwd()}"
        UI.message("paramaters:#{params}")
        
        work_path = File.expand_path(params[:git_directory])
        UI.message "Parameter git directory: #{work_path}"
        changelog = nil
        #git log  --graph --pretty=format:"- %s %h (%ad)" --date=format:"%y-%m-%d %H:%M:%S"
        Dir.chdir(work_path) do
          command = ["git log $(git describe --tags --abbrev=0)..HEAD"]
          command << "--grep=\"fix\""
          command << "--grep=\"feat\""
          command << "--graph --pretty=format:\"- %s %h (%ad)\" --date=format:\"%y-%m-%d %H:%M:%S\""
          changelog = Actions.sh(command.compact.join(" "), log: false).chomp
        end
        Actions.lane_context[SharedValues::YK_GIT_CHANGES] = changelog
        return changelog
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "git 提交记录"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "git 提交记录"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :git_directory,
                                       env_name: "FL_GIT_DIRECTORY", # The name of the environment variable
                                       description: "API Token for GitChangesYkAction", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No API token for GitChangesYkAction given, pass using `api_token: 'token'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["YK_GIT_CHANGES", "从最近一个tag到当前commit的所有feat, fix标识的提交"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        "从最近一个tag到当前commit的所有feat, fix标识的提交, 格式为字符串"
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["stephen5652@126.com/stephenchen"]
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
