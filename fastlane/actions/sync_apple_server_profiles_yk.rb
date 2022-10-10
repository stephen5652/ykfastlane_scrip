require 'fastlane'

module Fastlane
  module Actions

    class SyncAppleServerProfilesYkAction < Action
      require_relative '../action_tools_yk/YKAppleAccountHelper'
      require_relative '../action_tools_yk/YKProfileTools'
      require_relative '../action_tools_yk/YKProfileGitTool'

      include YKAppleModule::AccountHelper
      include YKProfileModule::YKProfileEnv
      include YKProfileModule::YKProfileGitExecute

      def self.run(params)
        puts("params:#{params.values}")

        #调试代码
        user = params[:user_name].blank? ? "stephen5652@126.com" : params[:user_name]
        password = params[:password].blank? ? "CXX565289910cxx" : params[:password]

        bundle_ids = params[:bundle_ids]
        result = YKAppleModule::AccountHelper::AccountClient.login(user, password)
        bundle_ids_str = params[:bundle_ids]
        bundle_ids_arr = bundle_ids.split(",")
        Fastlane::UI.important("bundle_ids_arr:#{bundle_ids_arr}")
        profile_arr = result.select_team_profile(bundle_ids_arr)
        puts("account_profiles:#{profile_arr.to_json}")

        file_path_arr = []
        profile_arr.each do |one|
          file_path_arr.append(one[:file_path])
        end
        self.install_catch_profiles(file_path_arr)

        profile_arr
      end

      def self.install_catch_profiles(path_arr)
        all_info_dict = {}
        path_arr.each do |one|
          name = YKProfileModule::YKProfileGitExecute.add_profile(one)
          info = YKProfileModule::YKProfileEnv.analysisProfile(one)
          info[:file_name] = name
          YKProfileModule::YKProfileGitExecute.update_profile_info(name, info)
          YKProfileModule::YKProfileEnv.install_one_profile(one)
        end
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :user_name,
                                       description: "Syncroise apple server profile exported user name", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.important("No user_name") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :password,
                                       description: "Syncroise apple server profile exported password", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.important("No password") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :bundle_ids,
                                       optional: true,
                                       description: "Syncroise apple server profile exported bundle_ids", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.important("No bundle_ids, will load all teams profiles") unless (value and not value.empty?)
                                       end),
        ]
      end

      def self.description
        "查看profile配置"
      end

      def self.details
        "查看并输出profile配置"
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        { "bundle_identifier" => { "method" => "profile_uuid" } }
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