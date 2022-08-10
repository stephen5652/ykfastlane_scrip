#!usr/bin/env ruby

require "podspec_editor"

module Fastlane
  module Actions
    module SharedValues
      POD_TRANSFER_VERSION_SUCCESS = :POD_TRANSFER_VERSION_SUCCESS
      POD_TRANSFER_VERSION_FAILED = :POD_TRANSFER_VERSION_FAILED
    end

    class PodTransferVersionAction < Action
      $project_path

      def self.runCmdArrSkipError(cmdArr)
        result = 0
        Dir.chdir($project_path) do
          Actions.sh(cmdArr.compact.join(" "), log: true, error_callback: lambda do |value|
            result = 1
          end).chomp
        end
        return result
      end

      def self.runCmdErrBack(cmdArr, error_callback: nil, &b)
        Dir.chdir($project_path) do
          result = Actions.sh(cmdArr.compact.join(" "), log: true, error_callback: error_callback, &b).chomp
          result
        end
      end

      def self.runCmdArr(cmdArr)
        Dir.chdir($project_path) do
          result = Actions.sh(cmdArr.compact.join(" "), log: true).chomp
          result
        end
      end

      def self.failedFunc(tag_ori, tag_new)
        arr = lane_context[:POD_TRANSFER_VERSION_FAILED]
        arr = [] if arr.blank?
        arr << tag_ori
        UI.important("one version failed: #{tag_ori}")
        lane_context[:POD_TRANSFER_VERSION_FAILED] = arr
      end

      def self.successFunc(tag_ori, tag_new)
        arr = lane_context[:POD_TRANSFER_VERSION_SUCCESS]
        arr = [] if arr.blank?
        arr << tag_ori
        UI.important("one version success: #{tag_ori}")
        lane_context[:POD_TRANSFER_VERSION_SUCCESS] = arr
      end

      def self.numeric?(lookAhead)
        lookAhead =~ /[0-9]/
      end

      def self.letter?(lookAhead)
        lookAhead =~ /[A-Za-z]/
      end

      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Parameter API Token: #{params[:version_name]}"
        $project_path = params[:project_path]
        tag_ori = params[:version_name]
        remote_yk = params[:remote_destioation_name]
        repo_name = params[:repo_name]
        tag_new = tag_ori + "-YKPRI"

        version_new = tag_new
        if self.letter?(version_new[0])
          version_new = version_new[1...]
        end
        puts "version_new:#{version_new}"

        cmd = []
        cmd << "git add . && git reset --hard && git checkout master"
        self.runCmdArrSkipError(cmd)

        cmd = []
        cmd << "git tag -d #{tag_new} && git push #{remote_yk} --delete #{tag_new}"
        self.runCmdArrSkipError(cmd)

        cmd = []
        cmd << "git branch -D #{tag_new}_branch"
        self.runCmdArrSkipError(cmd)

        cmd = []
        cmd = ["git checkout #{tag_ori} -b #{tag_new}_branch"]
        self.runCmdArrSkipError(cmd)

        file_path = File.join($project_path, File.basename($project_path) + ".podspec")
        cmd = []
        cmd << "pod ipc spec #{file_path}"
        result = self.runCmdArrSkipError(cmd)
        puts "convert result:\n#{result}"
        if result != 0
          self.failedFunc(tag_ori, tag_new)
          return result
        end

        # sh "shellcommand ./path"
        editor = PodspecEditor::Editor.new(spec_path: file_path)
        editor.spec.source.git = params[:remote_destioation_url]
        editor.spec.source.tag = tag_new
        editor.spec.version = version_new
        podName = editor.spec.name
        file_path_json = File.join($project_path, podName + ".podspec.json")
        puts "editor.current_json_content: #{editor.current_json_content}"
        File.rename(file_path, file_path_json)
        puts "new json podspec:#{file_path_json}"
        File.open(file_path_json, "w") { |file| file.puts(editor.current_json_content) }
        cmd = []
        cmd << "git add #{file_path_json}"
        cmd << " && git commit -m \"edit version #{tag_ori} to #{tag_new}\""
        cmd << " && git add . && git reset --hard"
        cmd << " && git tag -a #{tag_new} -m \"new version #{tag_new} for #{tag_ori}\""
        cmd << " && git push #{remote_yk} #{tag_new} "

        result = self.runCmdArrSkipError(cmd)
        if result != 0
          self.failedFunc(tag_ori, tag_new)
          return result
        end

        cmd = ["pod repo push #{repo_name} #{file_path_json} --allow-warnings --skip-import-validation --skip-tests --verbose"]
        puts "update command: #{cmd}"
        result = self.runCmdArrSkipError(cmd)
        if result != 0
          cmd = []
          cmd << "git add . && git reset --hard && git checkout master"
          self.runCmdArrSkipError(cmd)

          cmd = []
          cmd << "git branch -D #{tag_new}_branch"
          self.runCmdArrSkipError(cmd)

          cmd = []
          cmd << "git tag -d #{tag_new} && git push #{remote_yk} --delete #{tag_new}"
          self.runCmdArrSkipError(cmd)
          self.failedFunc(tag_ori, tag_new)
        else
          self.successFunc(tag_ori, tag_new)
        end

        puts "repo push result:#{result}"
        result
        # Actions.lane_context[SharedValues::POD_TRANSFER_VERSION_CUSTOM_VALUE] = "my_val"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: "YK_POD_PROJECT_PATH", # The name of the environment variable
                                       description: "Project path for project", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No project path for PodTransferVersionAction given, pass using `project_path: 'path'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: "YK_POD_TRANSFER_VERSION", # The name of the environment variable
                                       description: "Version name for PodTransferVersionAction", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No Version name for PodTransferVersionAction given, pass using `version_name: 'name'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :remote_destioation_url,
                                       description: "Url for new remote repository url", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No origin destioation url for PodTransferVersionAction given, pass using `remote_destioation_url: 'url'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :remote_destioation_name,
                                       description: "Url for new remote repository url", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No origin destioation name for PodTransferVersionAction given, pass using `remote_destioation_url: 'url'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :repo_name,
                                       env_name: "YK_POD_TRANSFER_REPO_NAME",
                                       description: "Pod repo name for transfer destination",
                                       verify_block: proc do |value|
                                         UI.user_error!("No destinationa repo for PodTransferVersionAction given, pass using `repo_name: 'repo name'`") unless (value and not value.empty?)
                                         # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        # [
        #   ["POD_TRANSFER_VERSION_CUSTOM_VALUE", "A description of what this value contains"],
        # ]
        [
                  ["POD_TRANSFER_VERSION_SUCCESS", "成功的版本数组"],
                  ["POD_TRANSFER_VERSION_FAILED", "失败的版本"],
                ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        #
        #  true
        #
        #  platform == :ios
        #
        #  [:ios, :mac].include?(platform)
        #

        platform == :ios
      end
    end
  end
end
