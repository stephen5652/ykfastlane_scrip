module Fastlane
  module Actions
    module SharedValues
      YK_BUILD_NUMBER ||= :YK_BUILD_NUMBER
      YK_VERSION_NUMBER ||= :YK_VERSION_NUMBER
      YK_PROJECT_PATH ||= :YK_PROJECT_PATH
      YK_WORKSPACE_PATH ||= :YK_WORKSPACE_PATH
    end

    class ProjectInfoYkAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message("paramaters:#{params}")

        self.ensure_workspace_project!(params)

        xcodeproj_path_or_dir = params[:xcodeproj] || "."
        xcodeproj_path_or_dir = File.expand_path(xcodeproj_path_or_dir)

        UI.message("project:#{xcodeproj_path_or_dir}")
        puts "xcodeproj:#{Dir.glob("#{xcodeproj_path_or_dir}/*.xcodeproj")}"
        if File.extname(xcodeproj_path_or_dir) == ".xcodeproj"
          if File.exist?(xcodeproj_path_or_dir) == false
            UI.user_error!("no *.xcodeproj:#{xcodeproj_path_or_dir}")
          end
        elsif Dir.glob("#{xcodeproj_path_or_dir}/*.xcodeproj").empty? == true
          UI.user_error!("no *.xcodeproj:#{xcodeproj_path_or_dir}")
        end

        xcodeproj_dir = File.extname(xcodeproj_path_or_dir) == ".xcodeproj" ? File.dirname(xcodeproj_path_or_dir) : xcodeproj_path_or_dir

        # version number
        target_name = params[:target]
        configuration = params[:configuration]

        project = get_project!(xcodeproj_path_or_dir)
        target = get_target!(project, target_name)
        plist_file = get_plist!(xcodeproj_dir, target, configuration)
        version_number = get_version_number_from_plist!(plist_file)

        # Get from build settings (or project settings) if needed (ex: $(MARKETING_VERSION) is default in Xcode 11)
        if version_number =~ /\$\(([\w\-]+)\)/
          version_number = get_version_number_from_build_settings!(target, $1, configuration) || get_version_number_from_build_settings!(project, $1, configuration)

          # ${MARKETING_VERSION} also works
        elsif version_number =~ /\$\{([\w\-]+)\}/
          version_number = get_version_number_from_build_settings!(target, $1, configuration) || get_version_number_from_build_settings!(project, $1, configuration)
        end

        # Error out if version_number is not set
        if version_number.nil?
          UI.user_error!("Unable to find Xcode build setting: #{$1}")
        end

        Actions.lane_context[SharedValues::YK_VERSION_NUMBER] = version_number

        UI.message("#{Actions.lane_context}")
      end

      def self.get_project!(xcodeproj_path_or_dir)
        require "xcodeproj"
        if File.extname(xcodeproj_path_or_dir) == ".xcodeproj"
          project_path = xcodeproj_path_or_dir
        else
          project_path = Dir.glob("#{xcodeproj_path_or_dir}/*.xcodeproj").first
        end

        if project_path && File.exist?(project_path)
          return Xcodeproj::Project.open(project_path)
        else
          UI.user_error!("Unable to find Xcode project at #{project_path || xcodeproj_path_or_dir}")
        end
      end

      def self.get_target!(project, target_name)
        targets = project.targets

        # Prompt targets if no name
        unless target_name

          # Gets non-test targets
          non_test_targets = targets.reject do |t|
            # Not all targets respond to `test_target_type?`
            t.respond_to?(:test_target_type?) && t.test_target_type?
          end

          # Returns if only one non-test target
          if non_test_targets.count == 1
            return targets.first
          end

          options = targets.map(&:name)
          target_name = UI.select("What target would you like to use?", options)
        end

        # Find target
        target = targets.find do |t|
          t.name == target_name
        end
        UI.user_error!("Cannot find target named '#{target_name}'") unless target

        target
      end

      def self.get_version_number_from_build_settings!(target, variable, configuration = nil)
        target.build_configurations.each do |config|
          if configuration.nil? || config.name == configuration
            value = config.resolve_build_setting(variable)
            return value if value
          end
        end

        return nil
      end

      def self.get_plist!(folder, target, configuration = nil)
        plist_files = target.resolved_build_setting("INFOPLIST_FILE", true)
        plist_files_count = plist_files.values.compact.uniq.count

        # Get plist file for specified configuration
        # Or: Prompt for configuration if plist has different files in each configurations
        # Else: Get first(only) plist value
        if configuration
          plist_file = plist_files[configuration]
        elsif plist_files_count > 1
          options = plist_files.keys
          selected = UI.select("What build configuration would you like to use?", options)
          plist_file = plist_files[selected]
        else
          plist_file = plist_files.values.first
        end

        # $(SRCROOT) is the path of where the XcodeProject is
        # We can just set this as empty string since we join with `folder` below
        if plist_file.include?("$(SRCROOT)/")
          plist_file.gsub!("$(SRCROOT)/", "")
        end

        # plist_file can be `Relative` or `Absolute` path.
        # Make to `Absolute` path when plist_file is `Relative` path
        unless File.exist?(plist_file)
          plist_file = File.absolute_path(File.join(folder, plist_file))
        end

        UI.user_error!("Cannot find plist file: #{plist_file}") unless File.exist?(plist_file)

        plist_file
      end

      def self.get_version_number_from_plist!(plist_file)
        plist = Xcodeproj::Plist.read_from_path(plist_file)
        UI.user_error!("Unable to read plist: #{plist_file}") unless plist

        plist["CFBundleShortVersionString"]
      end

      def self.ensure_workspace_project!(paramas)
=begin
1. 检查 是否有 workspace 参数, 如果有就需要核对是文件是否是.xcworkspace文件
2. 如果是workspace 文件夹,则需要确认该路径下只有一个.xcworkspace文件,否则就要报错.
=end
        puts "cxx debug workspace:#{paramas[:xcworkspace]}"

        workspace = File.expand_path(paramas[:xcworkspace])
        if paramas[:xcworkspace].blank? == false
          if File.extname(workspace) == ".xcworkspace"
            paramas[:xcworkspace] = workspace
          else
            list = Dir.glob("#{workspace}/*.xcworkspace")
            if list.empty?
              UI.user_error!("No workspace at path:#{workspace}")
            elsif list.length > 2
              UI.user_error!("Multiple workspace at path:#{workspace}")
            end

            workspace = Dir.glob("#{workspace}/*.xcworkspace").first
          end
        end

        paramas[:xcworkspace] = workspace
        Actions.lane_context[SharedValues::YK_WORKSPACE_PATH] = paramas[:xcworkspace]
        UI.important("xcworkspace:#{workspace}")

        project = paramas[:xcodeproj].blank? ? File.dirname(workspace) : File.expand_path(paramas[:xcodeproj])
        if File.extname(project) != ".xcodeproj"
          list = Dir.glob("#{project}/*.xcodeproj")
          if list.length > 2
            UI.user_error!("Multiple .xcodeproj at path, so you should pass the absolute one:#{project}")
          elsif list.empty?
            UI.user_error!("No .xcodeproj at path:#{project}")
          end
          project = list.first
        end

        paramas[:xcodeproj] = project
        Actions.lane_context[SharedValues::YK_PROJECT_PATH] = project
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
          FastlaneCore::ConfigItem.new(key: :xcworkspace,
                                       description: "xxx.xcworkspace的路径[绝对路径 .xcworkspace文件路径或者文件夹路径]", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No xxx.xcworkspace for ProjectInfoYkAction given, pass using `xcworkspace: './xxx.xcworkspace'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       description: "xxx.xcodeproj的路径[绝对路径 .xcodeproj文件路径或者文件夹路径]", # a short description of this parameter
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("No xcodeproj for ProjectInfoYkAction given, pass using `xcodeproj: './xxx.xcodeproj'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :target,
                                       description: "target to get version number",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       description: "Configuration name, optional. Will be needed if you have altered the configurations from the default or your version number depends on the configuration selected",
                                       optional: true),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ["YK_BUILD_NUMBER", "builde number for project"],
          ["YK_VERSION_NUMBER", "version number for target"],
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["stephen5652@126.com/stephenchen"]
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
