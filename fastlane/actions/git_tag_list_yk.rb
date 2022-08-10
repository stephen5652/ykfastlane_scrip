module Fastlane
  module Actions
    module SharedValues
      GIT_TAG_LIST_YK_TAGS_LIST ||= :GIT_TAG_LIST_YK_TAGS_LIST
      GIT_TAG_LIST_YK_TAGS_YKVERSION ||= :GIT_TAG_LIST_YK_TAGS_YKVERSION
      GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA ||= :GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA
    end

    class GitTagListYkAction < Action
      @taile_str = "-YKPRI"
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Parameter work path: #{params[:work_path]}"

        # sh "shellcommand ./path"
        work_path = params[:work_path]
        tags_str = nil
        #git log  --graph --pretty=format:"- %s %h (%ad)" --date=format:"%y-%m-%d %H:%M:%S"
        command = ["cd #{work_path}"]
        command << " && git fetch --all --verbose"
        Actions.sh(command.compact.join(" "), log: true).chomp

        command = ["cd #{work_path}"]
        command << " && git tag"
        tags_str = Actions.sh(command.compact.join(" "), log: false).chomp

        arr = tags_str.split("\n")
        UI.important("tags:\t#{arr}")

        arr_extra_tag = [].concat(arr)
        arr_ykprivate = []
        for iterm in arr
          puts "tag: #{iterm}"
          if iterm.include?(@taile_str)
            puts "is private tag"
            arr_ykprivate << iterm
            arr_extra_tag.delete(iterm)
            arr_extra_tag.delete(iterm.split(@taile_str).first)
          end
        end

        puts "ykprivate tag:#{arr_ykprivate}"
        puts "github extra tag:#{arr_extra_tag}"

        Actions.lane_context[SharedValues::GIT_TAG_LIST_YK_TAGS_LIST] = arr
        Actions.lane_context[SharedValues::GIT_TAG_LIST_YK_TAGS_YKVERSION] = arr_ykprivate
        Actions.lane_context[SharedValues::GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA] = arr_extra_tag

        result = {}
        result[:GIT_TAG_LIST_YK_TAGS_LIST] = arr
        result[:GIT_TAG_LIST_YK_TAGS_YKVERSION] = arr_ykprivate
        result[:GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA] = arr_extra_tag

        result
        # Actions.lane_context[SharedValues::GIT_TAG_LIST_YK_CUSTOM_VALUE] = "my_val"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :work_path,
                                       description: "work_path GitTagListYkAction", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No workpath for GitTagListYkAction given, pass using `work_path: 'work_path'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
        # FastlaneCore::ConfigItem.new(key: :development,
        #                              env_name: "FL_GIT_TAG_LIST_YK_DEVELOPMENT",
        #                              description: "Create a development certificate instead of a distribution one",
        #                              is_string: false, # true: verifies the input is a string, false: every kind of value
        #                              default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["GIT_TAG_LIST_YK_TAGS_LIST", "tag 数组"],
          ["GIT_TAG_LIST_YK_TAGS_YKVERSION", "已经迁移的tag"],
          ["GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA", "未迁移的tag"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        {
          GIT_TAG_LIST_YK_TAGS_LIST: ["1.0.0", "1.0.1", "1.1.0", "1.1.2"],
          GIT_TAG_LIST_YK_TAGS_YKVERSION: ["1.1.0", "1.1.2"],
          GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA: ["1.0.0", "1.0.1"],
        }
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
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
