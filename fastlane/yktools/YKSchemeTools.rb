require 'fastlane'
require 'rexml'
require 'json'
require 'xcodeproj'
module YKXcode
  class YKScheme
    include REXML
    attr_accessor :name, :project, :path, :buildableName, :print_name, :archive_configuration, :bundle_identifier

    def initialize
      @name, @project, @path, @buildableName, @print_name, @archive_configuration, @bundle_identifier = ""
    end

    def to_json(*a)
      {
        :name => @name,
        :project => @project,
        :path => @path,
        :buildableName => @buildableName,
        :print_name => @print_name,
        :archive_configuration => @archive_configuration,
        :bundle_identifier => @bundle_identifier,
      }.to_json(*a)
    end

    def self.find_scheme(scheme, workspace)
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

      result = self.new()
      result.name = scheme

      projects_arr.each do |project|
        arr = Dir.glob(File.join(project, "xcshareddata/xcschemes") + "/**/#{scheme}.xcscheme")
        if arr.length > 0
          result.path = arr.first
          result.project = project
          break
        end
      end

      Fastlane::UI.user_error!("Not found scheme [#{scheme}] from workspace:#{workspace}") if result.path.blank?
      result.analysis_scheme()
      result.analysis_target()

      puts("scheme:#{result.to_json()}")
      result
    end

    def analysis_scheme()
      #.xcscheme 解析
      file = File.new(self.path)
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
      arr = project_obj.targets.select { |element|
        element.name == self.name
      }

      Fastlane::UI.user_error!("not found target[#{self.name}] for project:#{self.project}") if arr.blank?
      target = arr.first

      cons_arr = target.build_configurations.select { |one|
        one.name == self.archive_configuration
      }
      Fastlane::UI.user_error!("not found target[#{self.name}] configuration[#{self.archive_configuration}] for project:#{self.project}") if cons_arr.blank?
      con = cons_arr.first

      bundle_id = con.resolve_build_setting("PRODUCT_BUNDLE_IDENTIFIER")
      Fastlane::UI.user_error!("not found target[#{self.name}] configuration[#{self.archive_configuration}] bundleId from project:#{self.project}") if bundle_id.blank?
      self.bundle_identifier = bundle_id

    end

  end
end