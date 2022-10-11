module Fastlane
  module Actions

    class InstallCertificateP12YkAction < Action
      require_relative '../action_tools_yk/YKProfileTools'
      require_relative '../action_tools_yk/YKProfileGitTool'

      include YKProfileModule::YKCertificateP12Execute
      include YKProfileModule::YKProfileGitExecute

      def self.run(params)
        password = params[:password]
        file_path = params[:file_path]

        name = YKProfileModule::YKCertificateP12Execute.add_one_certificate(file_path)
        YKProfileModule::YKCertificateP12Execute.install_one_certificate(file_path, password)
        info = YKProfileModule::YKCertificateP12Execute.analysis_p12(file_path, password)

        YKProfileModule::YKProfileGitExecute.update_certificate_info(name, info)
        YKProfileModule::YKProfileGitExecute.git_commit("Add certificate:#{name}")
      end

      def self.description
        "查看profile配置"
      end

      def self.details
        "查看并输出profile配置"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :password,
                                       description: "Password for certificate p12 file", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No password for certificate p12 file. Pass using `password: 'password'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       description: "File path for certificate p12 file", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No certificate p12 file path. Pass using `file_path: 'absolute_file_path'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
        ]
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
