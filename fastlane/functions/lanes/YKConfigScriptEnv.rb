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
    all_scheme_info = analysis_xcode_workspace_yk(
      xcworkspace: workspace,
      )

    all_scheme_info.each_pair do |k, v|
      arr = v[:bundle_identifiers]
      bundle_id_set = bundle_id_set | arr
      # arr.each do |one_bundle|
      #   bundle_id_set.add(one_bundle)
      # end
    end
  end

  bundle_ids_para_str = options[:bundle_ids]
  bundle_arr = bundle_ids_para_str.split(",")
  bundle_id_set = bundle_id_set | bundle_arr

  bundle_ids_str = Array(bundle_id_set).join(",")
  if bundle_ids_str.blank?
    # 调试代码
    dest_bundle_arr = [
      "com.Isale.cn.YKLeXiangBan",
      "com.yeahka.agent",
      "com.lsale.cn.LSsaleChainForIpad",
      "com.topsida.lyl",
      "com.YeahKa.KuaiFuBa",
    ]
    bundle_ids_str = dest_bundle_arr.join(',')
  end


  # bundle_ids_str = ""
  profile_info_arr = sync_apple_server_profiles_yk(
  user_name: options[:user_name].blank? ?  "" :  options[:user_name],
  password: options[:password].blank? ? "" :  options[:password],
  bundle_ids: bundle_ids_str
  )
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
    安装mobileprovision 文件.
    描述:
    1.需要创建一个git仓库, 仓库中有一个 provision_files_enterprise 文件夹;
    2. provision_files_enterprise 文件夹里面放置所有的描述文件;
    3. 该指令需要在provision_files_enterprise文件夹的上级的根目录执行.

    参数:
    profile_path: [必需] profile 文件绝对路径

    command example: ykfastlane yk_install_mobileprovision profile_path:\"xxxxx\"
" ""
lane :yk_install_mobileprovision do |options|
  Fastlane::UI.important("yk_install_mobileprovision options:#{options}")
  running_path = options[:script_run_path]
  profile_path = options[:profile_path]
  if profile_path.include?(running_path) == false
    profile_path = File.expand_path(File.join(running_path, profile_path))
  end
  analysis_mobileprofile_yk(profile_path: profile_path)
end

