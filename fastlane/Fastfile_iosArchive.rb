#!/usr/bin/env ruby
#

require_relative "functions/archive_defines"
require 'fastlane'

@wxwork_webhook = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
@script_run_path = ""

@archive_para = YkArchiveCi::YkArchiveParamater.new()
@ipa_info = YkArchiveCi::YkIpaInfo.new()
@git_commit_info = YkArchiveCi::YkGitCommitInfo.new()
@release_note = YkArchiveCi::YkReleaseNoteInfo.new()

desc "" "
    打iOS测试包,并上传蒲公英,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      pgyer_api: [必需] 蒲公英平台api_key
      pgyer_user[必需] 蒲公英平台 user_key
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_pgyer scheme:ShuabaoQ pgyer_api:\"123456\" pgyer_user:\"123456\" wxwork_access_token:\"wxworktokem\" note:\"note\" xcworkspace:\"~/Desktop/ShuaBao\" cocoapods:1 flutter_directory:\"flutter_directory\"
" ""
lane :archive_pgyer do |options|
  puts "archive_pgyer options:#{options}"

  archive_info_hash = {}
  Dir.chdir(@script_run_path) do
    archive_info_hash = archive_ios_func(options)
  end

  upload_hash = up_pgyer_func(options[:ipa], options[:pgyer_api], options[:pgyer_user], options[:note])

  title = "Test app \"#{archive_info_hash[:app_name]}\"  new version."
  message_hash = {
    msg_title: title,
    msg_app_name: archive_info_hash[:app_name],
    msg_app_version: archive_info_hash[:app_version_build],
    msg_app_size: archive_info_hash[:app_size],
    commit_id: archive_info_hash[:commit_id],
    commit_message: archive_info_hash[:commit_message],
    release_note: archive_info_hash[:release_note],

    msg_app_url: upload_hash[:app_url],
  }

  wx_message_func(options[:wxwork_access_token], message_hash)
end

desc "" "
    打iOS测试包,并上传Fir,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      fir_api_token: [必需] Fir平台api token
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_fire scheme:ShuabaoQ fir_api_token:\"fir_api_token\" wxwork_access_token:\"wxworktokem\" note:\"note\" xcworkspace:\"~/Desktop/ShuaBao\" cocoapods:1 flutter_directory:\"flutter_directory\"
" ""
lane :archive_fire do |options|
  puts "archive_fire options:#{options}"

  archive_info_hash = {}
  Dir.chdir(@script_run_path) do
    archive_info_hash = archive_ios_func(options)
  end

  upload_hash = up_fir_func(options[:ipa], options[:fir_api_token], options[:note])

  title = "Test app \"#{archive_info_hash[:app_name]}\"  new version."
  message_hash = {
    msg_title: title,
    msg_app_name: archive_info_hash[:app_name],
    msg_app_version: archive_info_hash[:app_version_build],
    msg_app_size: archive_info_hash[:app_size],
    commit_id: archive_info_hash[:commit_id],
    commit_message: archive_info_hash[:commit_message],
    release_note: archive_info_hash[:release_note],

    msg_app_url: upload_hash[:app_url],
  }

  wx_message_func(options[:wxwork_access_token], message_hash)
end

desc "" "
    安装mobileprovision 文件.
    描述: 
    1.需要创建一个git仓库, 仓库中有一个 provision_files_enterprise 文件夹;
    2. provision_files_enterprise 文件夹里面放置所有的描述文件;
    3. 该指令需要在provision_files_enterprise文件夹的上级的根目录执行.

    该指令没有参数.

    command example: ykfastlane yk_install_mobileprovision_enterprise
 " ""
lane :yk_install_mobileprovision_enterprise do |options|
  Dir.chdir(@script_run_path) do
    profile_dir = File.expand_path(File.join(Dir.pwd(), "provision_files_enterprise"))
    yk_install_mobileprovision(profile_dir)
  end
end

# 安装 .mobileprovisionfile
def yk_install_mobileprovision(pro_dir)
  UI.message("profile_dir:#{pro_dir}")
  list = Dir["#{pro_dir}/*.mobileprovision"]
  UI.message("pro_files:#{list}")

  if list.empty? == true
    UI.important("no mobileprovision files:#{pro_dir}")
    return
  end

  list.each do |f|
    install_provisioning_profile(path: f)
  end
end

desc "" "
    安装 certificate 文件.
    描述: 
    1. 需要创建一个git仓库, 仓库中有一个 certificate_files_enterprise 文件夹;
    2. certificate_files_enterprise 文件夹里面放置所有的证书文件;
    3. 所有的证书只能有一个密码
    4. 该指令需要在provision_files_enterprise文件夹的上级的根目录执行.

    参数: 
      password_keychain: [必需] 证书安装在 \"登录\" 的keychain项, 需要解锁keychain, 此字段一般是用户的开机密码.
      password_cer: [非必须] 如果证书有密码, 则需要传密码

    command example: ykfastlane yk_install_cetificates_enterprise password_cer:123456 password_keychain:123456
 " ""
lane :yk_install_cetificates_enterprise do |options|
  puts "script_run_path:#{@script_run_path}"
  Dir.chdir(@script_run_path) do
    password_cer = options[:password_cer].blank? ? "" : options[:password_cer]
    password_chain = options[:password_keychain].blank? ? "" : options[:password_keychain]
    cetificate_dir = File.expand_path(File.join(Dir.pwd(), "certificate_files_enterprise"))

    if password_chain.blank? == false ##解锁 keychain
      Actions.sh("security unlock-keychain -p \"#{password_chain}\" ~/Library/Keychains/login.keychain-db")
    end

    yk_install_cetificates(cetificate_dir, password_cer, password_chain)
  end
end

desc "" "
    reupload ipa to pgyer
    options are: ipa[require], note[optional], last_log[optional], pgyer_api[optional], pgyer_user[optional] wxwork_access_token[require]

    command example: ykfastlane re_upload_pgyer pgyer_api:\"1234\" pgyer_user:\"123456\" note:\"reupload ipa\" last_log:\"~/abc\" wxwork_access_token:\"wxwork_key\"
" ""
lane :re_upload_pgyer do |options|
  info_hash = sort_update_messages(options[:last_log], options[:note], options[:ipa])
  upload_hash = up_pgyer_func(info_hash[:ipa], options[:pgyer_api], options[:pgyer_user], info_hash[:note])

  message_hash = {
    msg_title: title,
    msg_app_name: info_hash[:app_name],
    msg_app_version: info_hash[:app_version_build],
    msg_app_size: info_hash[:app_size],

    msg_app_url: upload_hash[:app_url],
    commit_id: info_hash[:commit_id],
    commit_message: info_hash[:commit_message],
    release_note: info_hash[:release_note],
  }

  wx_message_func(options[:wxwork_access_token], message_hash)
end

desc "" "
    reupload ipa to fir
    options are: fir_api_token[required], last_log[optional] wxwork_access_token[require] note[optional]

    command example: ykfastlane re_upload_fir fir_api_token:\"1234\" wxwork_access_token:\"wxwork_key\" last_log:\"~/xx/x/directory\" note:\"reupload\"
" ""
lane :re_upload_fir do |options|
  info_hash = sort_update_messages(options[:last_log], options[:note], options[:ipa])
  upload_hash = up_fir_func(info_hash[:ipa], options[:fir_api_token], info_hash[:note])

  message_hash = {
    msg_title: info_hash[:title],
    msg_app_name: info_hash[:app_name],
    msg_app_version: info_hash[:app_version_build],
    msg_app_size: info_hash[:app_size],
    commit_id: info_hash[:commit_id],
    commit_message: info_hash[:commit_message],
    release_note: info_hash[:release_note],

    msg_app_url: upload_hash[:app_url],
  }

  wx_message_func(options[:wxwork_access_token], message_hash)
end

# 整理发包平台上传信息 和 企业微信通知信息
def sort_update_messages(log_file, note, ipa_file)
  log_file = File.exist?(File.expand_path(log_file)) unless log_file.blank?
  info_hash = {}
  if log_file.blank? and File.exist?(log_file)
    #读日志
    data = JSON.parse(File.read(log_file))
    puts "data:#{data}"
    options.merge!({
                     ipa: data["ipa"],
                     note: data["note"].blank? ? options[:note] + "--" + data["note"] : options[:note],
                   })

    info_hash = {
      ipa: ipa_file,
      app_name: data["app_name"],
      app_version_build: data["app_version_build"],
      app_size: data["app_size"],
      note: data["note"],
      release_note: note,
    }
    puts "old log:#{info_hash}"
  else
    ipa_info_hash = analyze_ipa_func(ipa_file)
    app_name = ipa_info_hash[:app_info_name]
    app_version = ipa_info_hash[:app_info_versionnumber]
    app_build = ipa_info_hash[:app_info_buildnumber]
    app_size = ipa_info_hash[:app_info_size]

    info_hash = {
      ipa: ipa_file,
      app_name: app_name,
      app_version_build: "#{app_version}(#{app_build})",
      app_size: app_size,
      note: note,
      release_note: note,
    }

    puts "recreate log:#{info_hash}"
  end

  title = "Test app \"#{info_hash["app_name"]}\"  new version."
  info_hash[:title] = title

  return info_hash
end

#安装开发证书
def yk_install_cetificates(cer_dir, pw_cer, pw_chain)
  UI.message("directory certificate_files:#{cer_dir}")
  list = Dir["#{cer_dir}/*.p12"]

  if list.empty? == true
    UI.important("no p12 files:#{cer_dir}")
    return
  end

  failed_files = []
  list.each do |f|
    result = import_certificate(
      certificate_path: f,
      certificate_password: pw_cer,
      keychain_name: "login",
      keychain_password: pw_chain,
    )

    failed_files << f unless result.is_a?(Array)
  end

  if failed_files.count
    UI.important("some files install failed:\n#{failed_files.compact.join("\n")}")
    UI.user_error!("some file install failed")
  end
end

after_all do |lane, options|
end

#寻找xcworkspace
def find_workspace_func(workspace_file_or_dir)
  cur_path = Dir.pwd()
  puts "cur_path: #{cur_path}"
  puts "find fils at path: #{workspace_file_or_dir}"
  result = ""
  if File.extname(workspace_file_or_dir) == ".xcworkspace"
    if File.exist?(workspace_file_or_dir) == false
      result = ""
    else
      result = workspace_file_or_dir
    end
  else
    list = Dir.glob("#{workspace_file_or_dir}/*.xcworkspace")
    puts "find files:#{list}"
    if list.empty? == true
      result = ""
    elsif list.count > 1
      result = ""
    else
      result = list.first
    end
  end

  return result
end

def archive_ios_func(options)
  #检验必要的key
  UI.user_error!("required key: scheme") if options[:scheme].blank?
  UI.user_error!("required key: xcworkspace") if options[:xcworkspace].blank?
  workspace_file = find_workspace_func(options[:xcworkspace])
  UI.user_error!("No workspace or Multiple at path:#{options[:xcworkspace]}") if workspace_file.blank?

  options[:xcworkspace] = workspace_file
  export_method = options[:export].blank? ? "enterprise" : options[:export]
  options[:export] = export_method

  flutter_exist = options[:flutter_directory].blank? ? false : true
  flutter_archive_yk(flutter_directory: options[:flutter_directory], skip_empty: true) if flutter_exist
  ## 有flutter,则必须 pod install
  if flutter_exist || (options.has_key?(:cocoapods) && Integer(options[:cocoapods]) == 1)
    podfile_dir = File.dirname(options[:xcworkspace])
    UI.important("Shoudle cocoapods install: podfile_dir:#{podfile_dir}")
    cocoapods(verbose: true, podfile: podfile_dir, use_bundle_exec: false)
  else
    UI.important("no run pod install")
  end

  @archive_para.scheme = options[:scheme]
  @archive_para.workspace = workspace_file
  @archive_para.export_method = export_method

  build_app(@archive_para.build_paramaters())

  #解析ipa && 重命名ipa输出路径
  ipa_info_hash = analyze_ipa_func(lane_context[:IPA_OUTPUT_PATH])
  @ipa_info.config_info(ipa_info_hash)

  app_name = ipa_info_hash[:app_info_name]
  app_version = ipa_info_hash[:app_info_versionnumber]
  app_build = ipa_info_hash[:app_info_buildnumber]
  app_size = ipa_info_hash[:app_info_size]

  path_rename = @archive_para.output_final_path(@ipa_info.version_build_des)
  Actions.sh("mv #{@archive_para.output_root_path_temp} #{path_rename}")
  path_root = path_rename
  ipa_path = @archive_para.ipa_final_path

  #创建 tag
  # create_tag_for_archive(scheme_name, app_version, app_build, time)

  #准备上传ipa包
  # {:author=>"stephen.chen", :author_email=>"stephenchen@xxxxx.com", :message=>"Merge branch 'master' into ID1024734\n", :commit_hash=>"4d6afbae52c86a79ab3e9f0f87eb55569f9cbd1a", :abbreviated_commit_hash=>"4d6afba"}
  commit = last_commit_yk(work_path: File.expand_path(options[:xcworkspace]))
  @git_commit_info.config_commit_info(commit)
  UI.important("last commit info:#{@git_commit_info.message}")

  release_note = options.has_key?(:note) ? options[:note] : "ios 测试包"
  update_note = "" "
  note:#{release_note}
  version:#{app_version}-#{app_build}
  archive_date:#{@archive_para.archive_time}
  commit_id:#{@git_commit_info.abbreviated_commit_hash}
  commit_message:#{@git_commit_info.message}
  " ""
  upload_options = {
    ipa: ipa_path,
    app_name: app_name,
    version_number: app_version,
    build_number: app_build,
    app_version_build: "#{app_version}(#{app_build})",
    app_size: app_size,
    archive_date: @archive_para.archive_time,
    note: update_note,
    commit_id: commit[:abbreviated_commit_hash],
    commit_message: commit[:message],
    release_note: release_note,
  }
  @release_note.config_info(upload_options)

  options.merge!(upload_options)
  # 存储 ipa 路径和 更新日志, 方便下次重新上传
  log_cache_path = File.join(path_root, "upload_paramater.json")
  file = File.new(log_cache_path, "w+")
  File.write(log_cache_path, JSON.dump(upload_options))

  return upload_options
end

# 创建tag
def create_tag_for_archive(scheme_name, version_number, build_number, archive_date)
  tag_name = "Test_#{scheme_name}_#{version_number}_#{build_number}_#{archive_date}"
  tag_des = "\"#{scheme_name} test version [#{version_number}_#{build_number}], archived at #{archive_date}\""

  tag_command = ""
  tag_command << "git tag -a #{tag_name} -m #{tag_des}"
  tag_command << " && git push origin #{tag_name}"
  Actions.sh(tag_command)
end

# 上传包到pgyer
def up_pgyer_func(ipa_file, pgyer_api, pgyer_user, update_note)
  puts "optoins:#{update_note}"
  UI.user_error!("pgyer require key:ipa") if ipa_file.blank?
  UI.user_error!("pgyer require key:pgyer_api") if pgyer_api.blank?
  UI.user_error!("pgyer require key:pgyer_user") if pgyer_user.blank?

  update_note = update_note.blank? ? "ios 测试包" : update_note
  #pgyer
  pgyer_result = pgyer_helper_yk(
    api_key: pgyer_api,
    user_key: pgyer_user,
    ipa: ipa_file,
    update_description: update_note,
  )

  app_url = pgyer_result[:YK_PGYER_DOWN_URL]
  content = pgyer_result[:YK_PGYER_UPDATE_MSG]

  return {
    app_url: app_url,
    content: content,
  }
end

# 上传包到fire
def up_fir_func(ipa_file, api_token, update_note)
  UI.user_error!("up_fir require ipa file:#{ipa_file}") if ipa_file.blank?
  UI.user_error!("pgyer require key:fir_api_token") if api_token.blank?
  update_note = "ios 测试包" if update_note.blank?

  fir_result = fir_cli_yk(
    open: true,
    need_release_id: true,
    api_token: api_token,
    specify_file_path: ipa_file,
    changelog: update_note,
  )

  ipa_info_hash = analyze_ipa_func(ipa_file)
  app_name = ipa_info_hash[:app_info_name]
  app_version = ipa_info_hash[:app_info_versionnumber] + "(#{ipa_info_hash[:app_info_buildnumber]})"
  app_size = ipa_info_hash[:app_info_size]
  app_url = fir_result[:YK_FIR_DOWN_URL]
  content = fir_result[:YK_FIR_UPDATE_MSG]
  title = "Test app \"#{app_name}\"  release message."

  return {
    app_url: app_url,
    content: content,
  }
end

lane :wx_message_notice do |options|
  UI.warn("skip notice failed message to enterprise wechat, since not robot token") if options[:wx_notice_token].blank?
  token = options[:wx_notice_token]
  title = options[:msg_title].blank? ? "CI work failed" : options[:msg_title]

  wxwork_notifier_yk(
    wxwork_webhook: @wxwork_webhook,
    wxwork_access_token: token,
    msg_title: title,
    release_note: options[:notice_message],
    )
end


def wx_message_func(access_token, message_hash)
  puts "web_hook:#{@wxwork_webhook}"

  if access_token.blank?
    UI.important("access_token is empty, no send message to wechat, but work still success")
    return 0
  end

  wxwork_notifier_yk(
    wxwork_webhook: @wxwork_webhook,
    wxwork_access_token: access_token,
    msg_title: message_hash[:msg_title],
    msg_app_name: message_hash[:msg_app_name],
    msg_app_version: message_hash[:msg_app_version],
    msg_app_size: message_hash[:msg_app_size],
    msg_app_url: message_hash[:msg_app_url],
    commit_id: message_hash[:commit_id],
    commit_message: message_hash[:commit_message],
    release_note: message_hash[:release_note],
  )
end

# 解析ipa包
def analyze_ipa_func(ipa_path)
  puts "analysis_ipa: #{ipa_path}"

  result = analyze_ios_ipa(ipa_path: ipa_path)
  UI.important("⚠️ Warning: analyze ipa finish") unless result != 0
  app_hash = lane_context[:AnalyzeIosIpaActionResultHash][:app]
  app_info_hash = app_hash[:info]
  app_info_categories_hash = app_hash[:categories]
  info_options = {
    app_info_name: app_info_hash[:display_name].blank? ? app_info_hash[:executable] : app_info_hash[:display_name],
    app_info_buildnumber: app_info_hash[:version],
    app_info_versionnumber: app_info_hash[:short_version],
    app_info_size: app_hash[:format_size],
  }

  UI.important("app_info:#{info_options}")
  return info_options
end

lane :clear_buile_temp do |options|
  UI.message("work failed, should remove temp dir:#{@archive_para.output_root_path_temp}")
  if Dir.exist?(@archive_para.output_root_path_temp)
    FileUtils.remove_dir(@archive_para.output_root_path_temp, true)
  else
    UI.message("temp path not existed:#{@archive_para.output_root_path_temp}")
  end
end

desc "private lane, cannot be used. Just used for developing to testing some action."
lane :test_lane do |options|
  Dir.chdir(@script_run_path) do
    archive_lane_yk(options)
  end
end
