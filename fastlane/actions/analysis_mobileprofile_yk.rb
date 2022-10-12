require_relative '../action_tools_yk/YKProfileTools'

module Fastlane
  module Actions
    module SharedValues
      YK_GIT_CHANGES = :YK_GIT_CHANGES
    end

    class AnalysisMobileprofileYkAction < Action
      include YKProfileModule::YKProfileEnv

      def self.run(params)
        Fastlane::UI.important("paramas:#{params.values}")
        profile_str = params[:profile_path]
        arr = profile_str.split(",")
        arr.each do |profile|
          if File.exist?(profile) == false
            Fastlane::UI.important("Profile not existed: #{profile}")
            next
          end

          self.install_one_profile(profile)
        end
      end

      def self.install_one_profile(profile)
        YKProfileModule::YKProfileEnv.install_profiles([profile])
        info = YKProfileModule::YKProfileEnv.analysisProfile(profile)
        puts("profile_info:#{info}")
        elements = info["Entitlements"]
        bundle_id = elements["application-identifier"]
        bundle_id_prefix_arr = info["ApplicationIdentifierPrefix"]
        bundle_id_prefix_arr.each do |one|
          bundle_id = bundle_id.gsub("#{one}.", "")
        end
        uuid = info["UUID"]
        method = info["method_type"]
        YKProfileModule::YKProfileEnv.update_archive_profile_info(uuid, method, bundle_id)
      end

      def self.description
        "解析，并安装 .mobileprofile"
      end

      def self.details
        "根据默认配置，寻找到对应的profile"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :profile_path,
                                       description: "ios bundle identifier", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error("No bundle identifier") unless (value and not value.empty?)
                                       end),
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        {
          :profile_uuid => "profile_uuid",
          :export_method => "export_method",
          :profile_path => "profile_path"
        }
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
