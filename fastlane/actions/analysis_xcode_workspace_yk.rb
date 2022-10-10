require 'rexml/document'

require_relative '../action_tools_yk/YKSchemeTools'
module Fastlane
  module Actions

    class AnalysisXcodeWorkspaceYkAction < Action
      include REXML
      def self.run(params)
        puts "params:#{params.class}:#{params.values}" # FastlaneCore::Configuration
        workspace = File.expand_path(params[:xcworkspace])

        UI.user_error!("Workspace not existed! -- #{workspace}") unless File.exist?(workspace)

        puts("start analysis workspace:#{workspace}")
        workspace = YKXcode::YKScheme.find_workspace(workspace)
        scheme_path_arr = YKXcode::YKScheme.all_shared_schemes(workspace)
        scheme_info_dict = YKXcode::YKScheme.analysis_scheme_path_arr(workspace, scheme_path_arr)
        puts("all_shared_schemes:#{scheme_info_dict.to_json}")

        scheme_info_dict
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "解析 .xcworkspace"
      end

      def self.details
        "解析 .xcworkspace 下 某一个 scheme 对应的 target, bundle_id, version number, build number"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :xcworkspace,
                                       description: ".xcworkspace path", # a short description of this parameter
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.warn("No .xcworkspace path") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["YK_GIT_CHANGES", "从最近一个tag到当前commit的所有feat, fix标识的提交"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
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