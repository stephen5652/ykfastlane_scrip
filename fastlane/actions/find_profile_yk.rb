require 'yaml'
require_relative '../action_tools_yk/YKProfileTools'

module Fastlane
  module Actions

    class FindProfileYkAction < Action

      def self.run(params)
        puts("find profile for:#{params.values}")
        yml = YKProfileModule::YKProfileEnv.load_profile_yml()
        if yml[params[:bundle_identifier]] == nil
          return {}
        end

        result = yml[params[:bundle_identifier]][params[:export_method]]
        return result == nil ? {} : result
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "根据配置，寻找profile"
      end

      def self.details
        "根据默认配置，寻找到对应的profile"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :bundle_identifier,
                                       description: "ios bundle identifier", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error("No bundle identifier") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :export_method,
                                       description: "ios archive exported method", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error("No exported method") unless (value and not value.empty?)
                                       end),
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        {"bundle_identifier" => "profile_uuid"}
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