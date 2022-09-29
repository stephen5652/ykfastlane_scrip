require 'rexml/document'

require_relative '../action_tools_yk/YKSchemeTools'
module Fastlane
  module Actions
    module SharedValues
      YK_GIT_CHANGES = :YK_GIT_CHANGES
    end

    class AnalysisXcodeWorkspaceYkAction < Action
      include REXML
      def self.run(params)
        puts "params:#{params.class}:#{params.values}" # FastlaneCore::Configuration
        workspace = params[:xcworkspace]
        scheme = params[:scheme]
        UI.user_error!("Workspace not existed! -- #{workspace}") unless File.exist?(workspace)

        puts("start analysis workspace:#{workspace}")
        scheme_obj = YKXcode::YKScheme.find_scheme(scheme, workspace)

        {
          :scheme => scheme_obj.name,
          :bundle_identifiers => scheme_obj.bundle_identifiers,
          :print_name => scheme_obj.print_name,
          :project => scheme_obj.project,
          :workspace => scheme_obj.workspace,
        }
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
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       description: "scheme name", # a short description of this parameter
                                       optional: false,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("Analysis workspace need scheme name") unless (value and not value.empty?)
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