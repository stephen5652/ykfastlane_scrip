#!/usr/bin/env ruby
#

require_relative 'YKConfigSCriptEnvExecute'

desc "" "
    配置 企业微信机器人， fir平台token, pgyer平台token
    参数:
      fir_api_token: [可选] fir平台token
      pgyer_api: [可选] 蒲公英平台api_key
      pgyer_user[可选] 蒲公英平台 user_key
      wxwork_access_token: [可选] 企业微信机器人 webhook中的key字段
      tf_user_name: [必需] apple id
      tf_pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
    command example: ykfastlane update_archive_env fir_api_token:\"xxx\" pgyer_api:\"123456\" pgyer_user:\"123456\" wxwork_access_token:\"wxworktoken\"
" ""

lane :update_archive_env do |options|
  env = YKFastScriptConfigModule::ArchiveEnv.new
  env.config_fir(options[:fir_api_token])
  env.config_pgyer(options[:pgyer_user], options[:pgyer_api])
  env.config_wx_access_token(options[:wxwork_access_token])
  env.config_tf(options[:tf_user_name], options[:tf_pass_word])
  env.config_execute
end

desc "" "
  通过企业微信机器人，发送消息
      参数：
        wx_notice_token：[可选] 企业微信机器人 webhook中的key字段
        msg_title: [可选] 微信消息标题
        notice_message: [可选] 微信消息内容
" ""

lane :wx_message_notice do |options|
  title = options[:msg_title]
  msg = options[:notice_message]
  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_notice_info(title, msg)
  robot.token = options[:wx_notice_token]
  send_msg_to_wechat(robot, true)
end

desc "" "
  同步苹果开发者后台数据
      参数：
        user_name：apple account
        password: apple account password
        bundle_ids： bundle identifier array, used \",\" to separate each.
        workspace: workspace path
" ""

lane :sync_apple_profile do |options|

  bundle_id_set = Set.new()
  workspace = options[:workspace]

  if workspace.blank? == false && workspace.end_with?('.xcworkspace') == false
    Dir.chdir(@script_run_path) do
      workspace = File.expand_path(workspace)
    end

    arr = Dir.glob(File.join(workspace, '*.xcworkspace'))
    if arr.length > 0
      workspace = arr.first
    end
  end

  if workspace.blank? == false
    all_scheme_info = analysis_xcode_workspace_yk( xcworkspace: workspace)
    all_scheme_info.each_pair do |k, v|
      arr = v[:bundle_identifiers]
      bundle_id_set = bundle_id_set | arr
      # arr.each do |one_bundle|
      #   bundle_id_set.add(one_bundle)
      # end
    end
  end


  bundle_ids_para_str = options[:bundle_ids]
  if bundle_ids_para_str.blank? == false
    bundle_arr = bundle_ids_para_str.split(",")
    bundle_id_set = bundle_id_set | bundle_arr
  end

  bundle_ids_str = ""
  bundle_ids_str = Array(bundle_id_set).join(",") unless bundle_id_set.empty?

  # bundle_ids_str = ""
  profile_info_arr = sync_apple_server_profiles_yk(
    user_name: options[:user_name].blank? ? "" : options[:user_name],
    password: options[:password].blank? ? "" : options[:password],
    bundle_ids: bundle_ids_str
  )
end

desc """
    更新多个profile
    参数:
    profile_path: profile文件绝对路径，如果有多个，使用 , 隔开""
"""

lane :update_profiles do |options|
  puts("options:#{options}")
  para = options[:profile_path]
  arr_1 = []
  if para.blank? == false
    arr = para.split(",")
    Dir.chdir(options[:script_run_path]) do
      arr.each do |one|
        arr_1.append(File.expand_path(one))
      end
    end
  end
  str = ""
  str = arr_1.join(",") unless arr_1.count == 0
  analysis_mobileprofile_yk(profile_path: str)
end

desc "" "
    显示 profile 配置
    参数: 无参数
" ""
lane :list_profile_configs do |options|
  dict = list_profile_yk()
  Fastlane::UI.important(dict.to_json)
end

desc "" "
    安装p12
    参数:
    password: p12 密码
    cer_path: p12 文件绝对路径
" ""

lane :update_certificate_p12 do |options|

  password = options[:password]
  file_path = File.expand_path(options[:cer_path])
  Dir.chdir(options[:script_run_path]) do
    file_path = File.expand_path(file_path)
  end
  install_certificate_p12_yk(file_path: file_path, password: password)
end

desc """
    同步git仓库中的 certificate & profile, 如果未传入
，则执行git pull； 否则,覆盖原有的profile & certificate
    参数:
    profile_remote_url: profile & certificate
"""

lane :sync_certificate_profile do |options|
  remote = options[:profile_remote_url]
  sync_certificate_and_profile_yk(remote_url: remote)
end

desc """
    显示 profile & certificate 配置和文件信息
"""
lane :list_profile_certificate_config do |options|
  certificate_profile_list_detail_yk()
end

