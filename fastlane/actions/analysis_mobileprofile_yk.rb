require_relative '../action_tools_yk/YKProfileTools'
require_relative '../action_tools_yk/YKProfileGitTool'

module Fastlane
  module Actions
    module SharedValues
      YK_GIT_CHANGES = :YK_GIT_CHANGES
    end

    class AnalysisMobileprofileYkAction < Action
      include YKProfileModule::YKProfileEnv
      include YKProfileModule::YKProfileGitExecute

      def self.run(params)
        Fastlane::UI.important("paramas:#{params.values}")
        profile_str = params[:profile_path]
        arr = profile_str.split(",")
        name_arr = []
        arr.each do |profile|
          if File.exist?(profile) == false
            Fastlane::UI.important("Profile not existed: #{profile}")
            next
          end

          name = self.install_one_profile(profile)
          name_arr << File.basename(name)
        end

        msg = name_arr.join(", ")
        YKProfileModule::YKProfileGitExecute.git_commit("Update profiles: #{msg}")
      end

      def self.install_one_profile(profile)
        name = YKProfileModule::YKProfileGitExecute.add_profile(profile)
        info = YKProfileModule::YKProfileEnv.install_one_profile(profile)
        info[:file_name] = name
        YKProfileModule::YKProfileGitExecute.update_profile_info(name, info)
        name
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
