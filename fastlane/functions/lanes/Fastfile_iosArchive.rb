#!/usr/bin/env ruby
#

require 'yaml'
require 'json'

require_relative 'ykArchiveDefines'

desc "" "
    打iOS测试包,并上传蒲公英,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      pgyer_api: [必需] 蒲公英平台api_key
      pgyer_user[必需] 蒲公英平台 user_key
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.
      export: [可选] 包的类型, 包的类型, app-store, validation,ad-hoc, package, enterprise, development, developer-id, mac-application, 默认为enterprise

    command example: ykfastlane archive_pgyer scheme:ShuabaoQ pgyer_api:\"123456\" pgyer_user:\"123456\" wxwork_access_token:\"wxworktokem\" note:\"note\" xcworkspace:\"~/Desktop/ShuaBao\" cocoapods:1 flutter_directory:\"flutter_directory\"
" ""
lane :archive_pgyer do |options|
  puts "archive_pgyer options:#{options}"

  archive_info = archive_func(options[:xcworkspace], options[:scheme], options[:export], options[:cocoapods])

  commit = last_commit_yk(work_path: archive_info.workspace)
  commit_info = YKArchiveModule::YKGitCommitInfo.new().config_detail(commit, options[:branch_name])

  upload_info = YKArchiveModule::YKUploadPlatFormInfo.new().config_info($ipa_info, commit_info, archive_info.archive_time, options[:note])

  app_url = upload_pgyer_func_yk(upload_info, options[:pgyer_user], options[:pgyer_api])


  title = "Test app \"#{$ipa_info.display_name}\"  new version."
  token = options[:wxwork_access_token]
  if app_url.blank?
    title = "Test app upload to pgyer failed !!"
    token = YKArchiveConfig::Config.new.wx_access_token
  end

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, $ipa_info.display_name, $ipa_info.size, $ipa_info.version_build, $ipa_info.size, commit_info.abbreviated_commit_hash, commit_info.message, commit_info.branch, app_url)
  robot.token = token
  send_msg_to_wechat(robot, true)
end

desc "" "
    打iOS测试包,并上传Fir,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      fir_api_token: [必需] Fir平台api token
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      export: [可选] 包的类型, 包的类型, app-store, validation,ad-hoc, package, enterprise, development, developer-id, mac-application, 默认为enterprise
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_fir scheme:ShuabaoQ fir_api_token:\"fir_api_token\" wxwork_access_token:\"wxworktokem\" note:\"note\" xcworkspace:\"~/Desktop/ShuaBao\" cocoapods:1 flutter_directory:\"flutter_directory\"
" ""
lane :archive_fir do |options|
  puts "archive_fire options:#{options}"
  archive_info = archive_func(options[:xcworkspace], options[:scheme], options[:export], options[:cocoapods])

  commit = last_commit_yk(work_path: archive_info.workspace)
  commit_info = YKArchiveModule::YKGitCommitInfo.new().config_detail(commit, options[:branch_name])

  upload_info = YKArchiveModule::YKUploadPlatFormInfo.new().config_info($ipa_info, commit_info, archive_info.archive_time, options[:note])

  fir_url = upload_fir_func_yk(upload_info, options[:fir_api_token])
  yk_upload_result =  upload_ipa_platform_yk(upload_info)

  title = "Test app \"#{$ipa_info.display_name}\"  new version."
  token = options[:wxwork_access_token]
  if fir_url.blank?
    title = "Test app upload failed !!"
    token = YKArchiveConfig::Config.new.wx_access_token
  end

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, $ipa_info.display_name, $ipa_info.version_build, $ipa_info.size, commit_info.abbreviated_commit_hash, commit_info.message, commit_info.branch, upload_info.release_note, fir_url)
  robot.token = token
  send_msg_to_wechat(robot, true)
end

desc "" "
    打iOS测试包,并上传TF,发送结果给企业微信群
    参数:
      scheme: [必需]
      user_name: [必需] apple id
      pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
      yk_ipa_upload_api[可选] 私有ipa分发地址

      note: [可选] 测试包发包信息
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.
      wxwork_access_token: [可选] 企业微信机器人


    command example: ykfastlane archive_tf scheme:ShuabaoQ user_name:\"xxxx.com\" pass_word:\"xxx-xxx-xxx-xxx\" wxwork_access_token:\"wxworktokem\" note:\"note\" xcworkspace:\"~/Desktop/ShuaBao\" cocoapods:1 flutter_directory:\"flutter_directory\"
" ""
lane :archive_tf do |options|
  puts "archive_fire options:#{options}"
  options[:export] = "app-store"

  puts "archive_fire options:#{options}"
  archive_info = archive_func(options[:xcworkspace], options[:scheme], options[:export], options[:cocoapods])

  commit = last_commit_yk(work_path: archive_info.workspace)
  commit_info = YKArchiveModule::YKGitCommitInfo.new().config_detail(commit, options[:branch_name])

  upload_tf_result = upload_tf_func_yk($ipa_info, options[:user_name], options[:pass_word])
  title = "TF app \"#{$ipa_info.display_name}\"  new version."
  token = options[:wxwork_access_token]
  if upload_tf_result == false
    title = "TF app \"#{$ipa_info.display_name}\" archive success, but upload failed !!"
    token = YKArchiveConfig::Config.new.wx_access_token
  end

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, $ipa_info.display_name, $ipa_info.version_build, $ipa_info.size, commit_info.abbreviated_commit_hash, commit_info.message, commit_info.branch, options[:note], "")
  robot.token = token
  send_msg_to_wechat(robot, true)
end

desc "" "
   删除iOS打包产物文件夹
   参数:
   wxwork_access_token: [可选] 企业微信机器人
" ""

lane :clean_product_directory do |lane, options|
  YKArchiveModule::ArchiveInfo.clean_product_dir

  product_path = YKArchiveModule::Helper::YK_PRODUCT_ROOT_PATH
  mac_user = Actions.sh("whoami")
  
  detail = "" "
  mac_user: #{mac_user}
  product_directory: #{product_path}
  " ""
  Fastlane::UI.important("clean product directory: #{detail}")

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_notice_info("Clean product path", detail)
  robot.token = YKArchiveConfig::Config.new.wx_access_token
  if robot.has_token == false
    Fastlane::UI.important("Notify message to wechat failed, since no token.")
  else
    wxwork_notifier_yk(robot.robot_message_body) unless robot.token.blank?
  end
end

desc "" "
    上传TF,发送结果给企业微信群
    参数:
      ipa: [必需] ipa文件绝对路径
      user_name: [必需] apple id
      pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [可选] 企业微信机器人
      note: [可选] TF包发包信息,用以通知相关开发
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数

    command example: ykfastlane upload_ipa_to_tf ipa:\"xxxx/xxx/xx.ipa\" user_name:\"xxxx.com\" pass_word:\"xxx-xxx-xxx-xxx\" wxwork_access_token:\"wxworktokem\" note:\"note\"
" ""
lane :upload_ipa_to_tf do |options|
  options[:note] = "TF 测试包" unless options[:note].blank?
  puts "upload_ipa_to_tf options:#{options}"
  ipa_info = analysis_ipa_yk(options[:ipa])
  put("ipa_info:#{ipa_info.info_des}")

  token = options[:wxwork_access_token]
  if upload_tf_func_yk(ipa_info, options[:user_name], options[:pass_word])
    title = "TF app \"#{ipa_info.display_name}\"  new version."
  else
    Fastlane::UI.important("Upload TF failed:#{ipa_info.ipa_path}")
    title = "TF app upload failed \"#{ipa_info.display_name}\"."
    token = YKArchiveConfig::Config.new.wx_access_token
  end

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, ipa_info.display_name, ipa_info.size, ipa_info.version_build, ipa_info.size, "", "", options[:note], "")
  robot.token = token
  send_msg_to_wechat(robot, true)
end

desc "" "
    reupload ipa to pgyer
    options are: ipa[require], note[optional], last_log[optional], pgyer_api[optional], pgyer_user[optional] wxwork_access_token[require]

    command example: ykfastlane re_upload_pgyer pgyer_api:\"1234\" pgyer_user:\"123456\" note:\"reupload ipa\" last_log:\"~/abc\" wxwork_access_token:\"wxwork_key\"
" ""
lane :re_upload_pgyer do |options|
  puts("re_upload_pgyer options:#{options}")
  ipa_info = analysis_ipa_yk(options[:ipa])
  upload_info = YKArchiveModule::YKUploadPlatFormInfo.new().config_info(ipa_info, nil, "", options[:note])

  app_url = upload_pgyer_func_yk(upload_info, options[:pgyer_user], options[:pgyer_api])

  title = "Test app \"#{ipa_info.display_name}\"  new version."
  token = options[:wxwork_access_token]
  if app_url.blank?
    title = "Test app upload failed !!"
    token = YKArchiveConfig::Config.new.wx_access_token
  end
  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, ipa_info.display_name, ipa_info.version_build, ipa_info.size, "", "", "", "", app_url)
  robot.token = token
  send_msg_to_wechat(robot, true)
end

desc "" "
    reupload ipa to fir
    options are: fir_api_token[required], last_log[optional] wxwork_access_token[require] note[optional]

    command example: ykfastlane re_upload_fir fir_api_token:\"1234\" wxwork_access_token:\"wxwork_key\" last_log:\"~/xx/x/directory\" note:\"reupload\"
" ""
lane :re_upload_fir do |options|
  puts("re_upload_fir options:#{options}")
  ipa_info = analysis_ipa_yk(options[:ipa])
  put("ipa_info:#{ipa_info.info_des}")

  upload_info = YKArchiveModule::YKUploadPlatFormInfo.new().config_info(ipa_info, "", "", options[:note])
  app_url = upload_fir_func_yk(upload_info, options[:fir_api_token])

  title = "Test app \"#{ipa_info.display_name}\"  new version."
  token = options[:wxwork_access_token]
  if app_url.blank?
    title = "Test app upload failed !!"
    token = YKArchiveConfig::Config.new.wx_access_token
  end
  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_ipa_info(title, ipa_info.display_name, ipa_info.version_build, ipa_info.size, "", "", "", "", app_url)
  robot.token = token
  send_msg_to_wechat(robot, true)
end

lane :clear_build_temp do |lane, options|
  $para_archive.clean_tem_path
end

desc "private lane, cannot be used. Just used for developing to testing some action."
lane :test_lane do |options|
  Dir.chdir(@script_run_path) do
    archive_lane_yk(options)
  end
end
