require 'fastlane'

module YkArchiveCi
  module Configs
    YKSCRIPT_RUNNING_PATH = File.expand_path(Dir.pwd)
    YKPRODUCT_ROOT_PATH = File.expand_path(File.join(Dir.home, "iosYeahArchive"))
  end
end

module YkArchiveCi
  class YkPgyerInfo

    attr_accessor :user
    attr_accessor :api

    def initialize()

      @user, @api = ""

    end
  end

  class YkFireInfo

    attr_accessor :api_token

    def initialize()
      @api_token = ""
    end
  end

  class YkReleaseNoteInfo
    attr_accessor :ipa, :app_name, :version_number, :build_number, :app_size, :archive_date, :note, :commit_id, :commit_message, :release_note

    def initialize()
      @ipa, @app_name, @version_number, @build_number, @app_size, @archive_date, @note, @commit_id, @commit_message, @release_note = ""
    end

    def config_info(info_map)
      self.ipa = info_map[:ipa]
      self.app_name = info_map[:app_name]
      self.version_number = info_map[:version_number]
      self.build_number = info_map[:build_number]
      self.app_size = info_map[:app_size]
      self.archive_date = info_map[:archive_date]
      self.note = info_map[:note]
      self.commit_id = info_map[:commit_message]
      self.release_note = info_map[:release_note]
    end
  end

  class YkGitCommitInfo
    # {:author=>"stephen.chen", :author_email=>"stephenchen@xxxxx.com", :message=>"Merge branch 'master' into ID1024734\n", :commit_hash=>"4d6afbae52c86a79ab3e9f0f87eb55569f9cbd1a", :abbreviated_commit_hash=>"4d6afba"}
    #
    attr_accessor :author, :author_email, :message, :commit_hash, :abbreviated_commit_hash

    def initialize()

      @author, @author_email, @message, @commit_hash, @abbreviated_commit_hash = ""
    end

    def config_commit_info(info)
      self.author = info[:author]
      self.author_email = info[:author_email]
      self.message = info[:message]
      self.commit_hash = info[:commit_hash]
      self.abbreviated_commit_hash = info[:abbreviated_commit_hash]
    end
  end

  class YkArchiveParamater

    attr_accessor :workspace
    attr_accessor :scheme
    '' ' app-store, validation,ad-hoc, package,enterprise, development, developer-id, mac-application ' ''
    attr_accessor :export_method
    attr_accessor :export_xcargs
    attr_reader :ipa_final_path

    def initialize()

      @workspace, @scheme, @export_method, @ipa_final_path = ""
      @build_time_str = Time.new.strftime("%Y%m%d_%H%M")
      @export_xcargs = "-allowProvisioningUpdates"
    end

    def output_root_path_temp()
      if self.scheme.blank? || self.export_method.blank?
        ""
      else
        File.expand_path(File.join(Configs::YKPRODUCT_ROOT_PATH, self.scheme, "temp_#{self.export_method}_#{@build_time_str}"))
      end
    end

    def archive_time()
      @build_time_str
    end

    def output_final_path(ipa_version)
      v_str = ipa_version.blank? ? "unknownVersion" : ipa_version
      dir_name = "#{self.scheme}_#{v_str}_#{self.export_method}_#{@build_time_str}"
      result = File.join(Configs::YKPRODUCT_ROOT_PATH, [self.scheme, dir_name])
      @ipa_final_path = File.join(result, ["output", "#{self.scheme}.ipa"])
      result
    end

    def archive_path_temp()
      File.join(self.output_root_path_temp, "#{self.scheme}.xcarchive")
    end

    def build_path_temp()
      File.join(self.output_root_path_temp, "build")
    end

    def output_path_temp()
      File.join(self.output_root_path_temp, "output")
    end

    def ipa_path_temp()
      File.join(self.output_root_path_temp, ["output", "#{self.scheme}.ipa"])
    end

    def build_paramaters()

      { workspace: self.workspace,
        scheme: self.scheme, #项目名称
        clean: true,
        output_name: self.scheme,
        export_method: self.export_method,
        archive_path: self.archive_path_temp,
        build_path: self.build_path_temp,
        output_directory: self.output_path_temp,
        #       skip_profile_detection: true,
        export_options: {
          compileBitcode: false, #关闭bitcode rebuild
          stripSwiftSymbols: false, #此字段是为了节省导出包的时间, 对于swift混编项目,次字段会导致到处包的时间大大延长.
        },
        export_xcargs: self.export_xcargs,
      }
    end
  end

  class YkIpaInfo

    attr_accessor :app_name, :app_version, :app_build, :app_size

    def initialize()

      @app_name, @app_version, @app_build, @app_size = ""
    end

    def config_info(ipa_info_hash)
      self.app_name = ipa_info_hash[:app_info_name]
      self.app_version = ipa_info_hash[:app_info_versionnumber]
      self.app_build = ipa_info_hash[:app_info_buildnumber]
      self.app_size = ipa_info_hash[:app_info_size]
    end

    def version_build_des()
      self.app_version + "_#{self.app_build}"
    end
  end

  class YkWxNotificationInfo

  end
end
