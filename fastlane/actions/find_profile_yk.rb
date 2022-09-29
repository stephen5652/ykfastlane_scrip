require 'yaml'

module Fastlane
  module YKProfileEnv
    YK_CONFIG_GIT_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config/git_info.yml'))
    YK_CONFIG_PROFILE_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config/profile.yml'))
    def self.profile_config_path_yk()
      result = Fastlane::YKProfileEnv::YK_CONFIG_PROFILE_YAML
      result
    end
  end

  module Actions

    class FindProfileYkAction < Action

      def self.run(params)
        puts("find profile for:#{params.values}")
        config_path = YKProfileEnv.profile_config_path_yk()
        if File.exist?(config_path) == false
          return {}
        end

        f = File.open(config_path, 'r')
        yml = YAML.load(f, symbolize_names: false)
        f.close
        if yml == false
          yml = {}
        end
        puts("yml[#{yml.class}]:#{yml.to_json}")
        puts("profile_config_path:#{config_path}")
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