module Fastlane
  module Actions
    # module SharedValues
    #   WXWORK_NOTIFIER_YK_CUSTOM_VALUE = :WXWORK_NOTIFIER_YK_CUSTOM_VALUE
    # end

    class WxworkNotifierYkAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message("paramaters:#{params.values}")

        return if params[:wxwork_webhook].blank? && params[:wxwork_access_token].blank?

        webhook_url = params[:wxwork_webhook]
        webhook_url ||= "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
        webhook_url += "?key=#{params[:wxwork_access_token]}"
        puts "web hook url:#{webhook_url}"
=begin 
wxwork_webhook 企业微信机器人webhookurl
wxwork_access_token 企业微信机器人令牌
see: https://work.weixin.qq.com/api/doc/90000/90136/91770
=end

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

        mark_down_content = "# <font color=\"info\">#{params[:msg_title]}</font>\n"
        mark_down_content += "## app: <font color=\"comment\">#{params[:msg_app_name]}</font>\n" unless params[:msg_app_name].blank?
        mark_down_content += "## version: <font color=\"comment\">#{params[:msg_app_version]}</font>\n" unless params[:msg_app_version].blank?
        mark_down_content += "## size: <font color=\"comment\">#{params[:msg_app_size]}</font>\n" unless params[:msg_app_size].blank?
        mark_down_content += "## url: <font color=\"comment\">#{params[:msg_app_url]}</font>\n" unless params[:msg_app_url].blank?
        mark_down_content += "## download: <font color=\"warning\">[下载](#{params[:msg_app_url]})</font>\n" unless params[:msg_app_url].blank?
        mark_down_content += "## branch: <font color=\"comment\">#{params[:branch]}</font>\n" unless params[:branch].blank?
        mark_down_content += "## commit_id: <font color=\"comment\">#{params[:commit_id]}</font>\n" unless params[:commit_id].blank?
        mark_down_content += "## commit_message: \"#{params[:commit_message]}\"\n" unless params[:commit_message].blank?
        mark_down_content += "## release_note: #{params[:release_note]}\n" unless params[:release_note].blank?
        mark_down_content += "## info: \n#{params[:msg_detail]}\n" unless params[:msg_detail].blank?
        # mark_down_content += "## detail:\n #{params[:msg_content]}\n" if params[:msg_content].blank? == false

        wx_paramas_markdown = {
          "msgtype": "markdown",
          "markdown": {
            "content": mark_down_content,
          },
        }

        puts "wx_paramas_markdown:#{wx_paramas_markdown}"
        UI.message "Start send message to wxwork..."

        response_markdown = wx_client.post webhook_url, wx_paramas_markdown
        info = response_markdown.body
        #{"errcode"=>0, "errmsg"=>"ok"}
        UI.important("Warning: Send message to wework failed. but work is success") if info["errcode"] != 0

        # 此处补发一个文本版测消息是 因为企业微信有的版本识别不了markdown或者屏蔽某些链接
        text_content = "#{params[:msg_title]}\n"
        text_content += "app: #{params[:msg_app_name]}\n"
        text_content += "version: #{params[:msg_app_version]}\n"
        text_content += "size: #{params[:msg_app_size]}\n"
        text_content += "url: #{params[:msg_app_url]}\n"

        wx_paramas_text = {
          "msgtype": "text",
          "text": {
            "content": text_content,
            "mentioned_list": ["@all"],
          },
        }
        # wx_client.post webhook_url, wx_paramas_text

        # sh "shellcommand ./path"

        # Actions.lane_context[SharedValues::WXWORK_NOTIFIER_YK_CUSTOM_VALUE] = "my_val"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
=begin
wxwork_webhook
wxwork_access_token
msg_title
msg_content
msg_url
msg_picurl
=end
        [
          FastlaneCore::ConfigItem.new(key: :wxwork_webhook,
                                       description: "企业微信机器人web hook 的 url", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.error("No wxwork_webhook for WxworkNotifierYkAction given, pass using `wxwork_webhook: 'url'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :wxwork_access_token,
                                       description: "企业微信机器人web hook 的 key", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.error("No wxwork_access_token for WxworkNotifierYkAction given, pass using `wxwork_access_token: 'key'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :msg_title,
                                       description: "信息标题", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.error("No msg_title for WxworkNotifierYkAction given, pass using `msg_title: 'hello world'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :msg_app_name,
                                       description: "app 名称", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.warn("No msg_app_name for WxworkNotifierYkAction given, pass using `msg_title: 'hello world'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :msg_app_version,
                                       description: "app 版本", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.warn("No msg_app_version for WxworkNotifierYkAction given, pass using `msg_title: 'hello world'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :msg_app_size,
                                       description: "app 大小", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.warn("No msg_app_size for WxworkNotifierYkAction given, pass using `msg_title: 'hello world'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :msg_app_url,
                                       description: "app 下载链接", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                         UI.error("No msg_app_url for WxworkNotifierYkAction given, pass using `msg_title: 'hello world'`") unless (value and not value.empty?)
                                         # UI.error("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :commit_id,
                                       description: "git提交ID", # a short description of this parameter
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :commit_message,
                                       description: "git提交信息", # a short description of this parameter
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       description: "git分支名称", # a short description of this parameter
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :release_note,
                                       description: "发版信息", # a short description of this parameter
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :msg_detail,
                                       description: "详情", # a short description of this parameter
                                       is_string: true,
                                       optional: true),
        ]

      end

      def self.output
        # Define the shared values you are going to provide
        # Example
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        #
        #  true
        #
        #  platform == :ios
        #
        #  [:ios, :mac].include?(platform)
        #

        platform == :ios
      end
    end
  end
end
