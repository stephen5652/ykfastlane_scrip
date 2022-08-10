module Fastlane
  module Actions
    module SharedValues
      # FLUTTER_ARCHIVE_YK_CUSTOM_VALUE = :FLUTTER_ARCHIVE_YK_CUSTOM_VALUE
    end

    class FlutterArchiveYkAction < Action
      def self.run(params)
        UI.message("paramaters:#{params}")

        # fastlane will take care of reading in the parameter and fetching the environment variable:
        skip_empty = params[:skip_empty] ? params[:skip_empty] : false
        flutter_directory = params[:flutter_directory] ? File.expand_path(params[:flutter_directory]) : ""
        UI.important("skip flutter empty:#{params[:skip_empty]}")
        UI.important("flutter directory:#{flutter_directory}")

        pubspec_file = File.join(flutter_directory, "pubspec.yaml")
        if (flutter_directory.empty? || File.exist?(pubspec_file) == false) && skip_empty #忽略flutter 目录为空
          UI.important("Flutter skip, since no flutter projects")
          return true
        end

        if flutter_directory.empty? or File.exist?(pubspec_file) == false
          UI.user_error!("Flutter pubspec_file not exist:#{pubspec_file}")
        end

        # sh "shellcommand ./path"
        result = true
        command_prefix = ["cd #{flutter_directory}"]
        command = [command_prefix]
        command << "&& flutter clean --verbose"
        command << "&& flutter pub get --verbose"
        command << "&& flutter build ios --release --verbose"

        command_result = 0
        Actions.sh(
          command.compact.join(" "),
          log: true,
          error_callback: proc do |result|
            puts "flutter command reslut:#{result}"
          end,
          &proc do |code, result, command|
          puts "flutter code:#{code.exitstatus}"
          command_reslut = code.exitstatus
          puts "flutter command:#{command}"
        end
        )

        if command_result != 0
          UI.user_error!("Flutter build failed: #{flutter_directory}")
        end

        return true

        # Actions.lane_context[SharedValues::FLUTTER_ARCHIVE_YK_CUSTOM_VALUE] = "my_val"
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
          FastlaneCore::ConfigItem.new(key: :flutter_directory,
                                       description: "flutter_directory for FlutterArchiveYkAction", # a short description of this parameter
                                       #  is_string: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could find flutter directory at path '#{File.expand_path(value)}'") unless Dir.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :skip_empty,
                                       env_name: "FL_FLUTTER_ARCHIVE_YK_DEVELOPMENT",
                                       description: "忽略flutter不存在的情况, 有些项目可能没有flutter目录,此处设置忽略,会不终止构建",
                                       optional: true,
                                       type: Boolean,
                                       default_value: false), # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        # [
        #   ["FLUTTER_ARCHIVE_YK_CUSTOM_VALUE", "A description of what this value contains"],
        # ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
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
