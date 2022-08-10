#!usr/bin/env ruby

require 'Faraday'

class YKWxwork_podTransferResult
  attr_accessor :pod_name, :wx_webhook_url, :access_token, :versions_all, :versions_github_extra, :versions_moving, :versions_success, :versions_failed

  def initialize(access_token)
    self.access_token = access_token unless access_token.blank?
    self.wx_webhook_url = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send'
    puts "wxwork access token:#{access_token}"
  end

  def wx_send_url
    webhook_url = wx_webhook_url
    webhook_url += "?key=#{access_token}"
    webhook_url
  end
end

def sendWxworkMessage(transferResult)
  # fastlane will take care of reading in the parameter and fetching the environment variable:
  UI.message("paramaters:#{transferResult}")

  return if transferResult.access_token.blank?

  puts "web hook url:#{transferResult.wx_send_url}"
  # wxwork_webhook 企业微信机器人webhookurl
  # wxwork_access_token 企业微信机器人令牌
  # see: https://work.weixin.qq.com/api/doc/90000/90136/91770

  str_title = "\"#{transferResult.pod_name}\" transfer finished"
  str_name = transferResult.pod_name
  str_all = transferResult.versions_all.to_s
  str_moving = transferResult.versions_moving.to_s
  str_success = transferResult.versions_success.to_s
  str_failed = transferResult.versions_failed.to_s

  mark_down_content = "#{str_title}\n"
  mark_down_content += "## pod_name: <font color=\"comment\">#{str_name}</font>\n"
  mark_down_content += "## versions_all: <font color=\"comment\">#{str_all}</font>\n"
  mark_down_content += "## versions_moving: <font color=\"comment\">#{str_moving}</font>\n"
  mark_down_content += "## versions_success: <font color=\"comment\">#{str_success}</font>\n"
  mark_down_content += "## versions_failed: <font color=\"comment\">#{str_failed}</font>\n"

  text_content = "#{str_title}\n"
  text_content += "pod_name: #{str_name}\n"
  text_content += "versions_all: #{str_all}\n"
  text_content += "versions_moving: #{str_moving}\n"
  text_content += "versions_success: #{str_success}\n"
  text_content += "versions_failed: #{str_failed}\n"

  wx_paramas_markdown = {
    "msgtype": 'markdown',
    "markdown": {
      "content": mark_down_content
    }
  }

  puts "wx_paramas_markdown:#{wx_paramas_markdown}"
  UI.message 'Start send message to wxwork...'

  conn_options = {
    request: {
      timeout: 10,
      open_timeout: 20,
    },
  }
  wx_client = Faraday.new(nil, conn_options) do |c|
    c.request :json
    c.request :url_encoded
    c.response :json, content_type: /\bjson$/
    c.adapter :net_http
  end

  # response_markdown = wx_client.post transferResult.wx_send_url, wx_paramas_markdown
  # info = response_markdown.body
  #{"errcode"=>0, "errmsg"=>"ok"}
  # UI.important('Warning: Send message to wework failed. but work is success') if info['errcode'] != 0

  # 此处补发一个文本版测消息是 因为企业微信有的版本识别不了markdown或者屏蔽某些链接
  wx_paramas_text = {
    "msgtype": 'text',
    "text": {
      "content": text_content,
      "mentioned_list": ['@all']
    }
  }
  # wx_client.post transferResult.wx_send_url, wx_paramas_text

end