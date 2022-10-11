module Fastlane
  module Actions

    class SyncCertificateAndProfileYkAction < Action

      require_relative '../action_tools_yk/YKProfileGitTool'
      require_relative '../action_tools_yk/YKProfileTools'

      include YKProfileModule::YKProfileEnv
      include YKProfileModule::YKProfileGitExecute
      include YKProfileModule::YKCertificateP12Execute

      def self.run(params)
        puts("params:#{params.values}")
        Fastlane::UI.user_error!("Not existed profile and certificate, you should config these first") unless YKProfileModule::YKProfileGitExecute.existed_profile_certificate()

        result = YKProfileModule::YKProfileGitExecute.sync_profile_remote()
        Fastlane::UI.user_error!("Sync profile remote failed") unless remote.blank?

        profile_dict = YKProfileModule::YKProfileGitExecute.get_profile_info_dict()

        if profile_dict != nil
          profile_dict.each_pair do |name, info|
            path = YKProfileModule::YKProfileGitExecute.get_profile_path(name)
            if path.blank?
              Fastlane::UI.important("Not install profile[#{name}], since cannot find it.")
              next
            end

            YKProfileModule::YKProfileEnv.install_one_profile(path) unless path.blank?
          end
        else
          Fastlane::UI.important("No profile found")
        end

        cer_dict = YKProfileModule::YKProfileGitExecute.get_certificate_info_dict()
        if cer_dict != nil
          YKProfileModule::YKCertificateP12Execute.install_cers(cer_dict)
        else
          Fastlane::UI.important("No certificate p12 found")
        end

      end

      def self.description
        "同步 certificate & profile 配置"
      end

      def self.details
        "通过配置的git信息, 同步并安装 certificate & profile"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        # [
        #   FastlaneCore::ConfigItem.new(key: :password,
        #                                description: "Password for certificate p12 file", # a short description of this parameter
        #                                verify_block: proc do |value|
        #                                  UI.user_error!("No password for certificate p12 file. Pass using `password: 'password'`") unless (value and not value.empty?)
        #                                  # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
        #                                end),
        # ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        nil
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
