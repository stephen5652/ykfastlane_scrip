require 'fastlane'
require 'rexml'
require 'json'
require 'xcodeproj'
module YKXcode
  class YKScheme
    include REXML
    attr_accessor :name, :project, :workspace, :scheme_path, :buildableName, :print_name, :archive_configuration, :bundle_identifiers

    def initialize
      @name, @project, @workspace, @scheme_path, @archive_configuration = ""
      @bundle_identifiers, @buildableName = []
      @print_name = []
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

    def self.find_workspace(workspace)
      if workspace.end_with?('.xcworkspace') == false
        arr = Dir.glob(File.join(workspace, '*.xcworkspace'))
        Fastlane::UI.user_error!("Not found or mutable xcworkspace at path: #{workspace}") unless arr.length == 1
        workspace = arr.first
      end
      workspace
    end

    def self.all_projects(workspace)
      workspace = self.find_workspace(workspace)
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
      projects_arr
    end

    def self.all_shared_schemes(workspace)
      project_arr = self.all_projects(workspace)
      scheme_path_arr = []
      project_arr.each do |project|
        arr = Dir.glob(File.join(project, "xcshareddata/xcschemes") + "/**/*.xcscheme")
        scheme_path_arr += arr unless arr.count == 0
      end

      scheme_path_arr
    end

    def self.analysis_one_scheme(scheme_path)
      #.xcscheme 解析
      file = File.new(scheme_path)
      scheme_data = REXML::Document.new(file)
      scheme_info = {}

      buildableName_arr = []
      print_name_arr = []
      XPath.each(scheme_data, '//BuildAction/BuildActionEntries/BuildActionEntry/BuildableReference').each do |build|
        #REXML::Attributes
        puts("one build:#{build.attributes}")
        att_dict = build.attributes
        buildableName_arr << att_dict["BuildableName"]
        print_name_arr << att_dict["BlueprintName"]
      end

      scheme_info[:buildableName] = buildableName_arr
      scheme_info[:print_name] = print_name_arr

      XPath.each(scheme_data, '//ArchiveAction').each do |archive|
        scheme_info[:archive_configuration] = archive["buildConfiguration"]
      end

      scheme_name = File.basename(scheme_path, ".xcscheme")
      scheme_info[:scheme_name] = scheme_name

      project_path = "" + scheme_path
      arr = project_path.split(".xcodeproj")
      project_path.gsub!(arr.last, "")
      scheme_info[:scheme_path] = scheme_path
      scheme_info[:project_path] = project_path

      scheme_info
    end

    def self.analysis_scheme_path_arr(workspace, scheme_path_arr)
      result = {}
      scheme_path_arr.each do |one_path|
        scheme_info = self.analysis_one_scheme(one_path)

        bundle_ids = self.bundle_ids_to_one_scheme_info(scheme_info)
        scheme_info[:bundle_identifiers] = bundle_ids
        scheme_info[:workspace] = workspace

        result[scheme_info[:scheme_name]] = scheme_info
      end

      result
    end

    def self.bundle_ids_to_one_scheme_info(scheme_info)

      project_path = scheme_info[:project_path]
      print_name_arr = scheme_info[:print_name]
      scheme_name = scheme_info[:scheme_name]
      archive_configuration = scheme_info[:archive_configuration]

      project_obj = Xcodeproj::Project.open(project_path)
      target_arr = project_obj.targets.select do |one|
        print_name_arr.include?(one.name)
      end
      Fastlane::UI.user_error!("not found scheme[#{scheme_name}] target[#{print_name_arr}] for project:#{project_path}") if target_arr.blank?

      filter_target_arr = Set[]
      target_arr.each do |target|
        filter_target_arr.add(target)
        target.dependencies.each do |one_dependency|
          filter_target_arr.add(one_dependency.target)
        end
      end

      bundle_id_set = Set[]
      filter_target_arr.each do |target|
        puts("one target:#{target}")
        cons_arr = target.build_configurations.select { |one|
          one.name == archive_configuration
        }

        cons_arr.each do |one|
          bundle_id = one.resolve_build_setting("PRODUCT_BUNDLE_IDENTIFIER")
          bundle_id_set.add(bundle_id)
        end
      end

      bundle_ids = Array(bundle_id_set)
      bundle_ids
    end

  end
end