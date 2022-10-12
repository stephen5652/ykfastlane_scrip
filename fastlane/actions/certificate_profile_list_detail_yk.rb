require 'fastlane'

module Fastlane
  module Actions

    class CertificateProfileListDetailYkAction < Action
      require_relative '../action_tools_yk/YKProfileTools'
      require_relative '../action_tools_yk/YKProfileGitTool'

      include YKProfileModule::YKProfileGitExecute
      include YKProfileModule::YKProfileEnv

      def self.run(params)
        puts("params:#{params.values}")
        info_archive_profile = YKProfileModule::YKProfileEnv.load_profile_yml

        info_certificates = YKProfileModule::YKProfileGitExecute.get_certificate_info_dict
        info_profiles = YKProfileModule::YKProfileGitExecute.get_profile_info_dict
        info_git =  YKProfileModule::YKProfileGitExecute.get_profile_certificate_git_info

        Fastlane::UI.important("profile_certificate_git_info:#{info_git.to_json}\n")
        Fastlane::UI.important("certificate_files_info:#{info_certificates.to_json}\n")
        Fastlane::UI.important("profile_files_info:#{info_profiles.to_json}\n")
        Fastlane::UI.important("profile_files_archive_info:#{info_archive_profile.to_json}\n")
      end

      def self.description
        "显示certificate & profile 详细信息"
      end

      def self.details
        "显示certificate, profile, archive_profile_map, git 详情"
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