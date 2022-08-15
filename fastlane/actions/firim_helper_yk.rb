module Fastlane
  module Actions
    module SharedValues
      YK_DOWN_LOAD_SHORT ||= :YK_DOWN_LOAD_SHORT
      YK_APP_NAME ||= :YK_APP_NAME
      YK_APP_URL ||= :YK_APP_URL
    end

    class FirimHelperYkAction < Action
      def self.run(config)
        UI.message("paramaters:#{config}")

        require "firim"
        config.load_configuration_file("Firimfile")

        if !config[:ipa]
          config[:ipa] = Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] if Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]
        end

        ::Firim::Runner.new(config).run

        Actions.lane_context[SharedValues::YK_DOWN_LOAD_SHORT] = ENV["FIRIM_APP_SHORT"]
        Actions.lane_context[SharedValues::YK_APP_NAME] = ENV["FIRIM_APP_NAME"]
        Actions.lane_context[SharedValues::YK_APP_URL] = ENV["FIRIM_APP_URL"]
      end

      def self.output
        [
          ["YK_DOWN_LOAD_SHORT", "二维码链接"],
          ["YK_APP_NAME", "安装包 下载链接"],
          ["YK_APP_URL", "app icon 链接"],
        ]
      end

      def self.description
        "Uses firim to upload ipa/apk to fir.im"
      end

      def self.authors
        ["whlsxl"]
      end

      def self.available_options
        require "firim"
        require "firim/options"
        FastlaneCore::CommanderGenerator.new.generate(::Firim::Options.available_options)
      end

      # support ios/android now
      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
