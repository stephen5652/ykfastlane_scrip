#!/usr/bin/env ruby
#

require_relative '../scriptConfig/YKArchiveConfigTools'

module YKFastScriptConfigModule
  class ArchiveEnv
    include YKArchiveConfig::Helper
    attr_accessor :wxwork_access_token, :fir_api_token, :pgyer_user, :pgyer_api, :tf_user, :tf_password

    def initialize()
      @wxwork_access_token, @fir_api_token, @pgyer_user, @pgyer_api = ""
    end

    def config_pgyer(user, api)
      self.pgyer_user = user
      self.pgyer_api = api
      self
    end

    def config_fir(token)
      self.fir_api_token = token
      self
    end

    def config_wx_access_token(token)
      self.wxwork_access_token = token
      self
    end

    def config_tf(user, password)
      self.tf_user = user
      self.tf_password = password
    end

    def config_execute
      conf = YKArchiveConfig::Config.new()
      conf.wx_access_token_update(self.wxwork_access_token) unless self.wxwork_access_token.blank?
      conf.fir_token_update(self.fir_api_token) unless self.fir_api_token.blank?
      conf.pgyer_info_update(self.pgyer_user, self.pgyer_api) unless self.pgyer_api.blank? || self.pgyer_api.blank?
      conf.tf_info_update(self.tf_user, self.tf_password) unless self.tf_user.blank? || self .tf_password.blank?
    end

  end
end
