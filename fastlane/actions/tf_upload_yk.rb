require "fastlane/action"
# require 'byebug'

module Fastlane

  module Actions
    module SharedValues
      YK_TF_URL ||= :YK_TF_URL
    end

    class TfUploadYkAction < Action
      def self.run(params)
        UI.message("The tf_yk action is working!")
        UI.message("paramaters:#{params}")

        # xcrun altool --upload-app -f YKLeXiangBan.ipa -t ios -u stephen5652@126.com -p  xxxx-xxxx-xxxx-xxxx --verbose
        # sh "shellcommand ./path"
        result = true
        command = ["xcrun altool --upload-app"]
        command << " -f \"#{params[:specify_file_path]}\""
        command << " -t ios"
        command << " -u #{params[:user_name]}"
        password_part = "-p #{params[:pass_word]}"
        command << " #{password_part}"
        command << " --verbose" unless  params[:verbose].blank? || params[:verbose] == false

        command_result = 0

        shell_result = Actions.sh(
          command.compact.join(" "),
          log: true,
          error_callback: proc do |result|
            UI.important "test flight upload result:#{result}"
          end,
          &proc do |code, result, command|
            command_result = code.exitstatus
            puts "test flight result code[result:#{result}] -- code.exitstatus[#{code.exitstatus.class}]#{code.exitstatus}"
            sensitive_command = command.gsub(password_part, " -p ********")
            puts "tf command:#{sensitive_command}"
          end
        ).chomp

        puts "test flight shell return:#{shell_result}"
        puts "test flight finish code:#{command_result}"
        if command_result != 0
          UI.important("tf upload failed: #{params[:specify_file_path]}")
          return false
        end

        UI.important("tf upload success: #{params[:specify_file_path]}")
        return true

      end

      def self.description
        "upload ipa to apple test flight."
      end

      def self.authors
        ["stephen.chen"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        "tf app info"
      end

      def self.details
        # Optional:
        "upload ipa to test flight"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :user_name,
                                       env_name: "TF_YK_USER_NAME",
                                       description: "apple developer user name",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :specify_file_path,
                                       env_name: "FIR_SPECIFY_FILE_PATH",
                                       description: "FILE APP PATH",
                                       default_value: "",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :pass_word,
                                       env_name: "TF_YK_APPLE_COMMON_PASSWORD",
                                       description: "apple developer user account password, create it by visit: https://appleid.apple.com/account/manage",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       description: "show upload log",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true)
        ]
      end

      def self.output
        [
          ["YK_TF_URL", "安装包 下载链接"],
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end

      def self.find_app_location(file_path)
        file_path || Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]
      end
    end
  end
end
