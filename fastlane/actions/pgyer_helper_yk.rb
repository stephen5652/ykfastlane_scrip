require "fastlane/action"

module Fastlane
  module Actions
    module SharedValues
      YK_PGYER_APP_NAME ||= :YK_PGYER_APP_NAME
      YK_PGYER_APP_VERSION ||= :YK_PGYER_APP_VERSION
      YK_PGYER_QRCODE_URL ||= :YK_PGYER_QRCODE_URL
      YK_PGYER_QRCODE_URL_SHORT ||= :YK_PGYER_QRCODE_URL_SHORT
      YK_PGYER_DOWN_URL ||= :YK_PGYER_DOWN_URL
      YK_PGYER_ICON_URL ||= :YK_PGYER_ICON_URL
      YK_PGYER_UPDATE_TIME ||= :YK_PGYER_UPDATE_TIME
      YK_PGYER_UPDATE_MSG ||= :YK_PGYER_UPDATE_MSG
    end

    class PgyerHelperYkAction < Action
      def self.run(params)
        UI.message("The pgyer plugin is working.")
        UI.message("paramaters:#{params}")

        api_host = "http://qiniu-storage.pgyer.com/apiv1/app/upload"
        pgyer_upload_note_file_name = "./fastlane/pgyer_upload_note_file.txt"
        api_key = params[:api_key]
        user_key = params[:user_key]

        build_file = [
          params[:ipa],
          params[:apk],
        ].detect { |e| !e.to_s.empty? }

        if build_file.nil?
          UI.user_error!("You have to provide a build file")
        end

        UI.message "build_file: #{build_file}"

        password = params[:password]
        if password.nil?
          password = ""
        end

        update_description = params[:update_description]
        if update_description.nil?
          update_description = ""
        end

        install_type = params[:install_type]
        if install_type.nil?
          install_type = "1"
        end

        # start upload
        conn_options = {
          request: {
            timeout: 1000,
            open_timeout: 300,
          },
        }

        pgyer_client = Faraday.new(nil, conn_options) do |c|
          c.request :multipart
          c.request :url_encoded
          c.response :json, content_type: /\bjson$/
          c.adapter :net_http
        end

        params = {
          "_api_key" => api_key,
          "uKey" => user_key,
          "password" => password,
          "updateDescription" => update_description,
          "installType" => install_type,
          "file" => Faraday::UploadIO.new(build_file, "application/octet-stream"),
        }

        UI.message "Start upload #{build_file} to pgyer..."

        response = pgyer_client.post api_host, params
        info = response.body

        if info["code"] != 0
          UI.user_error!("PGYER Plugin Error: #{info["message"]}")
        end

        UI.message("pgyer result:#{info}")
        ###
        # {"code"=>0,
        # "message"=>"",
        # "data"=>{
        # "appKey"=>"29a73a54fc15f3f8a8a08268ad25966e",
        # "userKey"=>"09fa807e88d477b0de3c021c60cb33a8",
        # "appType"=>"1", "appIsLastest"=>"1",
        # "appFileSize"=>"81262042",
        # "appName"=>"刷宝商户版",
        # "appVersion"=>"345001",
        # "appVersionNo"=>"2",
        # "appBuildVersion"=>"11",
        # "appIdentifier"=>"www.shuabao.comQ",
        # "appIcon"=>"ba6e713d765bd2ced8e4e83f82c2b207",
        # "appDescription"=>"",
        # "appUpdateDescription"=>"note:ios 测试包\ncommit:856d4ba\nversion:345001-2",
        # "appScreenshots"=>"",
        # "appShortcutUrl"=>"0dn4",
        # "appCreated"=>"2021-10-19 16:18:13",
        # "appUpdated"=>"2021-10-19 16:18:13",
        # "appQRCodeURL"=>"http://www.pgyer.com/app/qrcodeHistory/b135cd11cd1c7592f2d37c805beab0bde522f4371c9a082e4b5e6bebf1ccd633"}}
        #
        ###

        # test_begin
        # puts "#{info}"
        # test_end

        # 下载地址唯一hash
        # https://www.pgyer.com/<hash>
        appName = info["data"]["appName"]
        verison_str = "#{info["data"]["appVersion"]}" + "_#{info["data"]["appVersionNo"]}"
        appKeyStr = info["data"]["appKey"]
        appReleaseDownLoadURL = "https://www.pgyer.com/#{appKeyStr}"

        shortUrl = info["data"]["appShortcutUrl"]
        appShortLoadUrl = "https://www.pgyer.com/#{shortUrl}"

        update_time = info["data"]["appUpdated"]
        update_msg = info["data"]["appUpdateDescription"]
        appQRCodeURL = info["data"]["appQRCodeURL"]

        # app 图标 唯一hash
        # https://appicon.pgyer.com/image/view/app_icons/<hash>
        appIconURLStr = "https://appicon.pgyer.com/image/view/app_icons/#{info["data"]["appIcon"]}"

        #lane_context 暂存

        result = {
          SharedValues::YK_PGYER_APP_NAME => appName,
          SharedValues::YK_PGYER_APP_VERSION => verison_str,
          SharedValues::YK_PGYER_QRCODE_URL => appQRCodeURL,
          SharedValues::YK_PGYER_DOWN_URL => appReleaseDownLoadURL,
          SharedValues::YK_PGYER_ICON_URL => appIconURLStr,
          SharedValues::YK_PGYER_UPDATE_MSG => update_msg,
          SharedValues::YK_PGYER_UPDATE_TIME => update_time,
          SharedValues::YK_PGYER_QRCODE_URL_SHORT => appShortLoadUrl,
        }

        Actions.lane_context[SharedValues::YK_PGYER_APP_NAME] = appName
        Actions.lane_context[SharedValues::YK_PGYER_APP_VERSION] = verison_str
        Actions.lane_context[SharedValues::YK_PGYER_QRCODE_URL] = appQRCodeURL
        Actions.lane_context[SharedValues::YK_PGYER_DOWN_URL] = appReleaseDownLoadURL
        Actions.lane_context[SharedValues::YK_PGYER_ICON_URL] = appIconURLStr
        Actions.lane_context[SharedValues::YK_PGYER_UPDATE_MSG] = update_msg
        Actions.lane_context[SharedValues::YK_PGYER_UPDATE_TIME] = update_time
        Actions.lane_context[SharedValues::YK_PGYER_QRCODE_URL_SHORT] = appShortLoadUrl

        UI.success "Upload success. Visit this URL to see: #{appReleaseDownLoadURL} \n"
        return result
      end

      def self.description
        "distribute app to pgyer beta testing service"
      end

      def self.authors
        ["nice2m"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "distribute app to pgyer beta testing service"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "PGYER_API_KEY",
                                       description: "api_key in your pgyer account",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :user_key,
                                       env_name: "PGYER_USER_KEY",
                                       description: "user_key in your pgyer account",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: "PGYER_APK",
                                       description: "Path to your APK file",
                                       default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       conflicting_options: [:ipa],
                                       conflict_block: proc do |value|
                                         UI.user_error!("You can't use 'apk' and '#{value.key}' options in one run")
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "PGYER_IPA",
                                       description: "Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action. For Mac zip the .app. For Android provide path to .apk file",
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       conflicting_options: [:apk],
                                       conflict_block: proc do |value|
                                         UI.user_error!("You can't use 'ipa' and '#{value.key}' options in one run")
                                       end),
          FastlaneCore::ConfigItem.new(key: :password,
                                       env_name: "PGYER_PASSWORD",
                                       description: "set password to protect app",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :update_description,
                                       env_name: "PGYER_UPDATE_DESCRIPTION",
                                       description: "set update description for app",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :install_type,
                                       env_name: "PGYER_INSTALL_TYPE",
                                       description: "set install type for app (1=public, 2=password, 3=invite). Please set as a string",
                                       optional: true,
                                       type: String),
        ]
      end

      def self.return_value
        "" "
        Returns the following dict:
        { YK_PGYER_QRCODE_URL: \"appQRCodeURL\", YK_PGYER_DOWN_URL: \"appReleaseDownLoadURL\", YK_PGYER_ICON_URL: \"appIconURLStr\",  YK_PGYER_UPDATE_MSG: \"update_msg\",
          YK_PGYER_UPDATE_TIME: \"update_description\",  YK_PGYER_QRCODE_URL_SHORT: \"appShortLoadUrl\" }
        " ""
      end

      def self.return_type
        :hash_of_strings
      end

      def self.sample_return_value
        {
          YK_PGYER_QRCODE_URL: "appQRCodeURL",
          YK_PGYER_APP_VERSION: "version(build)",
          YK_PGYER_DOWN_URL: "appReleaseDownLoadURL",
          YK_PGYER_ICON_URL: "appIconURLStr",
          YK_PGYER_UPDATE_MSG: "update_msg",
          YK_PGYER_UPDATE_TIME: "update_description",
          YK_PGYER_QRCODE_URL_SHORT: "appShortLoadUrl",
        }
      end

      def self.example_code
        [
          'commit = last_commit_yk(work_path: "~/a/b/c")
          pilot(changelog: commit[:message]) # message of commit
          author = commit[:author] # author of the commit
          author_email = commit[:author_email] # email of the author of the commit
          hash = commit[:commit_hash] # long sha of commit
          short_hash = commit[:abbreviated_commit_hash] # short sha of commit',
        ]
      end

      def self.output
        [
          ["YK_PGYER_QRCODE_URL", "二维码链接"],
          ["YK_PGYER_APP_VERSION", "版本号"],
          ["YK_PGYER_DOWN_URL", "安装包 下载链接"],
          ["YK_PGYER_ICON_URL", "app icon 链接"],
          ["YK_PGYER_UPDATE_TIME", "更新日期"],
          ["YK_PGYER_UPDATE_MSG", "更新日志"],
          ["YK_PGYER_QRCODE_URL_SHORT", "下载短链接"],
        ]
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["stephen5652@126.com/stephenchen"]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Platforms.md
        #
        [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
