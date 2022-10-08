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

