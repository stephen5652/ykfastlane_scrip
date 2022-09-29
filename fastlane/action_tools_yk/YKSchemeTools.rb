require 'fastlane'
require 'rexml'
require 'json'
require 'xcodeproj'
module YKXcode
  class YKScheme
    include REXML
    attr_accessor :name, :project, :workspace, :scheme_path, :buildableName, :print_name, :archive_configuration, :bundle_identifiers

    def initialize
      @name, @project, @workspace, @scheme_path, @buildableName, @print_name, @archive_configuration = ""
      @bundle_identifiers = []
    end

    def to_json(*a)
      {
        :name => @name,
        :project => @project,
        :workspace => @workspace,
        :scheme_path => @scheme_path,
        :buildableName => @buildableName,
        :print_name => @print_name,
        :archive_configuration => @archive_configuration,
        :bundle_identifiers => @bundle_identifiers,
      }.to_json(*a)
    end

    def self.find_scheme(scheme, workspace)
      result = self.new()
      result.name = scheme

      '''
      1. 根据workspace, 找到project
      2. 根据project,找到所有scheme
      3. 筛选scheme, 找到目标scheme
      4. 解析出scheme对应的project, target, configuration
      5. 解析project, 找到对应target, dependency_targets
      6. 找到对应target,以及dependency_targets对应的configuration 下的bundle_id
      '''

      result.analysis_workspace(workspace)
      result.analysis_scheme()
      result.analysis_target()

      puts("scheme:#{result.to_json()}")
      result
    end

    def analysis_scheme()
      #.xcscheme 解析
      file = File.new(self.scheme_path)
      scheme_data = REXML::Document.new(file)
      XPath.each(scheme_data, '//LaunchAction/BuildableProductRunnable/BuildableReference').each do |build|
        #REXML::Attributes
        puts("one build:#{build.attributes}")
        att_dict = build.attributes
        self.buildableName = att_dict["BuildableName"]
        self.print_name = att_dict["BlueprintName"]
      end

      XPath.each(scheme_data, '//ArchiveAction').each do |archive|
        self.archive_configuration = archive["buildConfiguration"]
      end
    end

    def analysis_target()
      project_obj = Xcodeproj::Project.open(self.project)
      target_arr = project_obj.targets.select do |one|
        one.name == self.print_name
      end
      Fastlane::UI.user_error!("not found target[#{self.name}] for project:#{self.project}") if target_arr.blank?

      filter_target_arr = Set[]
      target_arr.each do |target|
        filter_target_arr.add(target)
        target.dependencies.each do |one_dependency|
          filter_target_arr.add(one_dependency.target)
        end
      end

      bundle_id_arr = Set[]
      filter_target_arr.each do |target|
        puts("one target:#{target}")
        cons_arr = target.build_configurations.select { |one|
          one.name == self.archive_configuration
        }

        cons_arr.each do |one|
          bundle_id = one.resolve_build_setting("PRODUCT_BUNDLE_IDENTIFIER")
          bundle_id_arr.add(bundle_id)
        end
      end

      self.bundle_identifiers = Array(bundle_id_arr)
    end

    def analysis_workspace(workspace)
      if workspace.end_with?('.xcworkspace') == false
        arr = Dir.glob(File.join(workspace, '*.xcworkspace'))
        Fastlane::UI.user_error!("Not found or mutable xcworkspace at path: #{workspace}") unless arr.length == 1
        workspace = arr.first
      end

      self.workspace = workspace

      arr = Dir.glob("#{workspace}/**/contents.xcworkspacedata")
      Fastlane::UI.user_error!("Not found contents.xcworkspacedata") unless arr.length > 0
      workspace_contents = arr.first

      file = File.new(workspace_contents)
      docs = REXML::Document.new(file)

      workspace_dir = File.dirname(workspace)
      projects_arr = []
      XPath.each(docs, '//FileRef/@location').each do |group|
        str = group.to_s
        str = str.sub("group:", "")
        puts("one group:#{str}")
        str = File.join(workspace_dir, str)
        projects_arr.append(str)
      end
      puts("projects:#{projects_arr}")

      projects_arr.each do |project|
        arr = Dir.glob(File.join(project, "xcshareddata/xcschemes") + "/**/#{self.name}.xcscheme")
        if arr.length > 0
          self.scheme_path = arr.first
          self.project = project
          break
        end
      end

      Fastlane::UI.user_error!("Not found scheme [#{self.name}] from workspace:#{workspace}") if self.scheme_path.blank?
    end

  end
end