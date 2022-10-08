require_relative '../action_tools_yk/YKProfileTools'

module Fastlane
  module Actions

    class ListProfileYkAction < Action

      def self.run(params)
        puts("params:#{params.values}")
        yml = YKProfileModule::YKProfileEnv.load_profile_yml()
        yml
      end

      def self.description
        "查看profile配置"
      end

      def self.details
        "查看并输出profile配置"
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        {"bundle_identifier" => {"method" => "profile_uuid"}}
      end

      def self.authors
        ["stephen5652@126.com/stephenchen"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

    end
  end
end
