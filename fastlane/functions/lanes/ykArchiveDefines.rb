require 'fileutils'
require 'fastlane'
require 'httparty'

require_relative '../scriptConfig/YKArchiveConfigTools'

module YKArchiveModule
  module Helper
    YK_PRODUCT_ROOT_PATH = File.expand_path(File.join(Dir.home, 'iosYeahArchive'))

    def product_root_path
      YKArchiveModule::Helper::YK_PRODUCT_ROOT_PATH
    end
  end

  class ArchiveInfo
    include YKArchiveModule::Helper
    attr_accessor :scheme, :bundle_identifiers, :workspace, :export_method, :export_profile_dict, :ipa_path_temp,
                  :cocoapods_flag

    attr_reader :archive_time

    def initialize
      @scheme, @workspace, @export_method, @ipa_path_temp = ''
      @archive_time = Time.new.strftime('%Y%m%d_%H%M')
      @bundle_identifiers = []
      @export_profile_dict = {}
      @cocoapods_flag = false
    end

    def self.clean_product_dir
      Fastlane::UI.important("remove product direstore:#{Helper::YK_PRODUCT_ROOT_PATH}")
      FileUtils.remove_dir(Helper::YK_PRODUCT_ROOT_PATH, force: true)
    end

    def output_root_path_temp
      if scheme.blank? || export_method.blank?
        File.expand_path(File.join(product_root_path, "temp_#{archive_time}"))
      else
        File.expand_path(File.join(product_root_path, 'temp',
                                   "temp_#{scheme}_#{export_method}_#{archive_time}"))
      end
    end

    def output_root_path_final(ipa_version, ipa_build)
      v_str = ipa_version.blank? ? 'unknownVersion' : ipa_version
      b_str = ipa_build.blank? ? '' : "_#{ipa_build}"
      dest_str = v_str + b_str
      dir_name = "#{scheme}_#{dest_str}_#{export_method}_#{archive_time}"
      File.join(product_root_path, [scheme, dir_name])
    end

    def ipa_final_path(ipa_version, ipa_build)
      File.join(output_root_path_final(ipa_version, ipa_build), ['output', "#{scheme}.ipa"])
    end

    def archive_path_temp
      File.join(output_root_path_temp, "#{scheme}.xcarchive")
    end

    def build_path_temp
      File.join(output_root_path_temp, 'build')
    end

    def output_path_temp
      File.join(output_root_path_temp, 'output')
    end

    def clean_tem_path
      Fastlane::UI.important("Should clear_build_temp:#{output_root_path_temp}")
      if File.exist?(output_root_path_temp)
        FileUtils.remove_dir(output_root_path_temp, true) unless output_root_path_temp.blank?
        Fastlane::UI.important("Clean clear_build_temp:#{output_root_path_temp}")
      else
        Fastlane::UI.important('Not clear_build_temp, it is not existed.')
      end
    end

    def ipa_path_temp
      File.join(output_root_path_temp, ['output', "#{scheme}.ipa"])
    end

    def move_to_destination_path(ipa_version, ipa_build)
      dest_root_path = output_root_path_final(ipa_version, ipa_build)
      temp_root_path = output_root_path_temp
      puts("temp_root_path:#{temp_root_path}")
      puts("dest_root_path:#{dest_root_path}")

      FileUtils.mkdir_p(File.dirname(dest_root_path)) if File.exist?(File.dirname(dest_root_path)) == false

      FileUtils.mv(temp_root_path, dest_root_path, force: true, verbose: true)
    end

    def export_xcargs
      '-allowProvisioningUpdates'
    end

    def build_parameters
      export_options = {
        compileBitcode: false, # 关闭bitcode rebuild
        stripSwiftSymbols: false, # 此字段是为了节省导出包的时间, 对于swift混编项目,次字段会导致到处包的时间大大延长.
        manageAppVersionAndBuildNumber: false # 关闭apple store connect  管理build 号
      }

      puts("export_profile_dict:#{export_profile_dict}")
      skip_profile_detect = false
      if export_profile_dict.blank? == false && export_profile_dict.count == bundle_identifiers.count
        export_options.update({
                                provisioningProfiles: export_profile_dict
                              })
        skip_profile_detect = true
      end

      { workspace: workspace,
        scheme: scheme, # 项目名称
        clean: true,
        output_name: scheme,
        export_method: export_method,
        archive_path: archive_path_temp,
        build_path: build_path_temp,
        output_directory: output_path_temp,
        buildlog_path: build_path_temp,
        export_options: export_options,
        export_xcargs: export_xcargs,
        skip_profile_detection: skip_profile_detect }
    end
  end
end

$para_archive = YKArchiveModule::ArchiveInfo.new

def archive_func(workspace, scheme, export_method, cocoapods)
  all_scheme_info = analysis_xcode_workspace_yk(
    xcworkspace: workspace
  )

  $para_archive.scheme = scheme
  $para_archive.workspace = workspace

  scheme_info = all_scheme_info[scheme]
  if scheme_info.nil?
    Fastlane::UI.important("Not fount scheme[#{scheme}] from workspace:#{workspace}")
  else
    $para_archive.scheme = scheme_info[:scheme_name]
    $para_archive.workspace = scheme_info[:workspace]
    $para_archive.bundle_identifiers = scheme_info[:bundle_identifiers]
  end

  $para_archive.export_method = export_method.blank? ? 'enterprise' : export_method
  $para_archive.cocoapods_flag = Integer(cocoapods.blank? ? '0' : cocoapods) == 1

  profile_dict = {}
  $para_archive.bundle_identifiers.each do |one|
    profile_uuid = find_profile_uuid_yk(
      bundle_identifier: one,
      export_method: export_method
    )
    profile_dict[one] = profile_uuid unless profile_uuid.blank?
  end

  puts("profiles:#{profile_dict}")
  $para_archive.export_profile_dict = profile_dict

  puts("scheme info:#{scheme_info}\n")
  puts("build_parames:\n#{$para_archive.build_parameters}\n\n")

  podfile_dir = File.dirname($para_archive.workspace)
  cocoapods(verbose: true, podfile: podfile_dir, use_bundle_exec: false) unless $para_archive.cocoapods_flag == false

  para = $para_archive.build_parameters
  build_app(para)
  ipa_path = lane_context[:IPA_OUTPUT_PATH]
  $para_archive.ipa_path_temp = ipa_path

  puts("archive finish, ipa:#{$para_archive.ipa_path_temp}")
  analysis_ipa_yk($para_archive.ipa_path_temp)

  $para_archive.move_to_destination_path($ipa_info.version_number, $ipa_info.build_number)
  $ipa_info.ipa_path = $para_archive.ipa_final_path($ipa_info.version_number, $ipa_info.build_number)
  puts("ipa_info:#{$ipa_info.info_des}")
  $para_archive
end

module YKArchiveModule
  class YKIpaInfo
    attr_accessor :version_number, :build_number, :display_name, :size, :ipa_path, :identifier

    def initialize
      @version_number, @build_number, @display_name, @size, @ipa_path, @identifier = ''
    end

    def version_build
      version_number + '(' + build_number + ')'
    end

    def info_des
      {
        display_name: display_name,
        size: size,
        version_build: version_build,
        version_number: version_number,
        build_number: build_number,
        ipa_path: ipa_path
      }
    end
  end
end

$ipa_info = YKArchiveModule::YKIpaInfo.new

def analysis_ipa_yk(ipa_path)
  result = analyze_ios_ipa(ipa_path: ipa_path)
  UI.important('⚠️ Warning: analyze ipa finish') unless result != 0
  app_hash = lane_context[:AnalyzeIosIpaActionResultHash][:app]
  app_info_hash = app_hash[:info]
  app_info_categories_hash = app_hash[:categories]
  info_options = {
    app_info_name: app_info_hash[:display_name].blank? ? app_info_hash[:executable] : app_info_hash[:display_name],
    app_info_buildnumber: app_info_hash[:version],
    app_info_versionnumber: app_info_hash[:short_version],
    app_info_size: app_hash[:format_size],
    app_identifier: app_info_hash[:identifier]
  }

  $ipa_info.display_name = app_info_hash[:display_name].blank? ? app_info_hash[:executable] : app_info_hash[:display_name]
  $ipa_info.build_number = app_info_hash[:version]
  $ipa_info.version_number = app_info_hash[:short_version]
  $ipa_info.size = app_hash[:format_size]
  $ipa_info.ipa_path = ipa_path
  $ipa_info.identifier = app_info_hash[:identifier]

  $ipa_info
end

module YKArchiveModule
  class YKGitCommitInfo
    attr_accessor :author, :author_email, :commit_hash, :abbreviated_commit_hash, :message, :branch

    def initialize
      @author, @author_email, @commit_hash, @abbreviated_commit_hash, @branch, @message = ''
    end

    def config_detail(info, branch)
      self.author = info[:author]
      self.author_email = info[:author_email]
      self.message = info[:message]
      self.commit_hash = info[:commit_hash]
      self.abbreviated_commit_hash = info[:abbreviated_commit_hash]

      self.branch = info[:branch].blank? ? branch : info[:branch]

      self
    end
  end
end

module YKArchiveModule
  class YKUploadPlatFormInfo
    attr_accessor :release_note, :ipa_info, :commit_info, :archive_time, :ipa_url

    def initialize
      @release_note, @archive_time = ''
      @ipa_info = YKArchiveModule::YKIpaInfo.new
      @commit_info = YKArchiveModule::YKGitCommitInfo.new
      @ipa_url = ""
    end

    def config_info(ipa_info, commit_info, archive_time, note)
      self.ipa_info = ipa_info
      self.commit_info = commit_info
      self.archive_time = archive_time
      self.release_note = note.blank? ? 'ios 测试包' : note

      self
    end

    def upload_yk_map
      {
        "app_name": ipa_info.display_name.blank? ? '' : ipa_info.display_name,
        # "app_icon":ipa_info.display_name.blank? ?  '' :  ipa_info.display_name,
        "gitlab_url": "",
        "bundleId": ipa_info.identifier.blank? ? '' : ipa_info.identifier,
        # "app_type":"",
        "app_version": ipa_info.version_number.blank? ? '' : ipa_info.version_number,
        "app_buildNum": ipa_info.build_number.blank? ? '' : ipa_info.build_number,
        "operateTime": archive_time.blank? ? '' : archive_time,
        "downloadURL_in": '',
        "downloadURL_out": ipa_url.blank? ? '' : ipa_url,
        "git_branch": commit_info.branch.blank? ? '' : commit_info.branch,
        # git commit_id 缩短版
        "git_commitId": commit_info.abbreviated_commit_hash.blank? ? '' : commit_info.abbreviated_commit_hash,
        "git_updateTime": "",
        "operator": "",
        "git_committer": commit_info.author.blank? ? '' : commit_info.author,
        "release_note": release_note.blank? ? 'ios 测试包' : release_note,
        "git_commitDescription": commit_info.message.blank? ? '' : commit_info.message,
      }

    end

    def platform_release_note
      note = release_note.blank? ? 'ios 测试包' : release_note
      version = ipa_info.version_build.blank? ? '' : ipa_info.version_build
      commit_id = commit_info.abbreviated_commit_hash.blank? ? '' : commit_info.abbreviated_commit_hash
      commit_des = commit_info.message.blank? ? '' : commit_info.message
      git_branch = commit_info.branch.blank? ? '' : commit_info.branch
      result = '' "
      note:#{note}
      version:#{version}
      archive_date:#{archive_time}
      commit_id:#{commit_id}
      branch:#{git_branch}
      commit_message:#{commit_des}
      " ''
      puts "upload_platform_release_note:\n#{result}\n\n"
      result
    end
  end

  class YKRequest
    include HTTParty
    headers 'Content-Type' => 'application/json'

    def initialize
      self.class.base_uri YKArchiveConfig::Config.new.yk_ipa_platform_upload_url
      puts "🍉 #{self.class.base_uri}"
    end

    def upload_ipa_platform_yk(upload_info)
      puts("upload ipa to yk ipa-platform:#{ upload_info.upload_yk_map.to_json }")
      begin
        result = self.class.post("", body: upload_info.upload_yk_map.to_json)
        puts "upload  yk server  result: #{result}"
      rescue StandardError
        puts(("error:#{$!}"))
      end
    end
  end
end

# yk ipa 分发平台
#
def upload_ipa_platform_yk(upload_info)
  YKArchiveModule::YKRequest.new.upload_ipa_platform_yk(upload_info)
end

def upload_fir_func_yk(upload_info, fir_token)
  # YKArchiveModule::YKUploadPlatFormInfo

  token_user = fir_token.blank? ? YKArchiveConfig::Config.new.fir_token : fir_token
  fir_result = fir_cli_yk(
    open: true,
    need_release_id: true,
    api_token: token_user,
    specify_file_path: upload_info.ipa_info.ipa_path,
    changelog: upload_info.platform_release_note
  )

  fir_result[:YK_FIR_DOWN_URL]
end

def upload_pgyer_func_yk(upload_info, pgyer_user, pgyer_api)
  if pgyer_user.blank? || pgyer_api.blank?
    info = YKArchiveConfig::Config.new.pgyer_info
    pgyer_user = info[YKArchiveConfig::Helper::K_PGYER_USER]
    pgyer_api = info[YKArchiveConfig::Helper::K_PGYER_API]
  end

  pgyer_result = pgyer_helper_yk(
    api_key: pgyer_api,
    user_key: pgyer_user,
    ipa: upload_info.ipa_info.ipa_path,
    update_description: upload_info.platform_release_note
  )

  pgyer_result[:YK_PGYER_DOWN_URL]
end

def upload_tf_func_yk(ipa_info, user_name, password)
  if user_name.blank? || password.blank?
    info = YKArchiveConfig::Config.new.tf_info
    user_name = info[YKArchiveConfig::Helper::K_TF_USER]
    password = info[YKArchiveConfig::Helper::K_TF_PASSWORD]
  end

  tf_upload_yk(
    specify_file_path: ipa_info.ipa_path,
    user_name: user_name,
    pass_word: password,
    verbose: true
  )
end

module YKArchiveModule
  class YKWechatEnterpriseRobot
    attr_accessor :token
    attr_reader :body_info

    def initialize
      @token = ''
      @body_info = {}
    end

    def config_ipa_info(title, name, version, size, commit_id, commit_msg, branch, note, url)
      body_info.update({
                         msg_title: title,
                         msg_app_name: name,
                         msg_app_version: version,
                         msg_app_size: size,
                         commit_id: commit_id,
                         commit_message: commit_msg,
                         branch: branch,
                         release_note: note.blank? ? 'ios 测试包' : note,
                         msg_app_url: url
                       })
      self
    end

    def config_notice_info(title, detail)
      body_info.update({
                         msg_title: title,
                         msg_detail: detail
                       })
      self
    end

    def web_hook
      'https://qyapi.weixin.qq.com/cgi-bin/webhook/send'
    end

    def has_token
      token.blank? == false
    end

    def robot_message_body
      token_used = token.blank? ? YKArchiveConfig::Config.new.wx_access_token : token
      result = { wxwork_webhook: web_hook,
                 wxwork_access_token: token_used }
      result.update(body_info)
      result
    end
  end
end

def send_msg_to_wechat(wechat_robot, skip_no_token)
  # robot = YKArchiveModule::YKWechatEnterpriseRobot.new()
  robot = wechat_robot
  robot.token = YKArchiveConfig::Config.new.wx_access_token if robot.token.blank?
  if robot.has_token == false && skip_no_token == true
    UI.important('Wechat robot access_token is empty, do not send message to wechat, but work still success')
    return 0
  end

  wxwork_notifier_yk(robot.robot_message_body)
end
