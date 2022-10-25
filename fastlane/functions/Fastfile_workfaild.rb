#!/usr/bin/env ruby
#

require_relative "scriptConfig/YKArchiveConfigTools"
require_relative 'lanes/ykArchiveDefines'

def workfaild_yk(lane, exception, options)

  arr = []
  fast_file_path = options[:fast_file_path].sub(File.expand_path(Dir.home), "~")
  options[:fast_file_path] = nil

  first_lane = options[:first_lane]
  options[:first_lane] = nil

  options.each do |key, value|
    arr.append("#{key}:#{value}") unless value.blank?
  end

  cmd = "cd #{fast_file_path} && fastlane #{first_lane} "
  cmd_para = arr.join(" ")
  cmd << cmd_para

  detail = "" "
  failed_lane: #{lane}
  command: #{cmd}
  " ""
  Fastlane::UI.important("work_failed_yk: #{detail}")

  robot = YKArchiveModule::YKWechatEnterpriseRobot.new().config_notice_info("CI work failed", detail)
  robot.token = YKArchiveConfig::Config.new.wx_access_token
  if robot.has_token == false
    Fastlane::UI.important("Notify error message to wechat failed, since no token.")
  else
    wxwork_notifier_yk(robot.robot_message_body) unless robot.token.blank?
  end
end