require 'yaml'
require 'fileutils'

require_relative '../YKYmlTool'

module YKArchiveConfig
  module Helper
    include YKYmlModule::Tool
    PATH_CONFIG_ROOT_DIR = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config'))
    PATH_CONFIG_ARCHIVE_DETAIL = File.join(PATH_CONFIG_ROOT_DIR, 'archive_config.yml')

    K_WX_ACCESS_TOKEN = :wx_access_token
    K_FIR_API_TOKEN = :fir_api_token

    K_PGYER_INFO = :pgyer_info_key
    K_PGYER_USER = :pgyer_user
    K_PGYER_API = :pgyer_api

    K_TF_INFO = :test_flight
    K_TF_USER = :user_name
    K_TF_PASSWORD = :pass_word

    def load_config_value(key)
      puts("fastlane_script_env_path:#{PATH_CONFIG_ARCHIVE_DETAIL}")
      YKYmlModule::Tool.load_yml_value(PATH_CONFIG_ARCHIVE_DETAIL, key)
    end

    def update_config_value(key, value)
      YKYmlModule::Tool.update_yml(PATH_CONFIG_ARCHIVE_DETAIL, key, value)
    end

    def load_config
      YKYmlModule::Tool.load_yml(PATH_CONFIG_ARCHIVE_DETAIL)
    end
  end
end

module YKArchiveConfig
  class Config
    include YKArchiveConfig::Helper

    def wx_access_token
      self.load_config_value(K_WX_ACCESS_TOKEN)
    end

    def wx_access_token_update(token)
      self.update_config_value(K_WX_ACCESS_TOKEN, token)
    end

    def fir_token
      self.load_config_value(K_FIR_API_TOKEN)
    end

    def fir_token_update(token)
      self.update_config_value(K_FIR_API_TOKEN, token)
    end

    def pgyer_info
      self.load_config_value(K_PGYER_INFO)
    end

    def pgyer_info_update(user, api)
      dict = {
        K_PGYER_USER => user,
        K_PGYER_API => api,
      }
      self.update_config_value(K_PGYER_INFO, dict)
    end

    def tf_info
      self.load_config_value(K_TF_INFO)
    end

    def tf_info_update(user_name, pass_word)
      dict = {
        K_TF_USER => user_name,
        K_TF_PASSWORD => pass_word,
      }
      self.update_config_value(K_TF_INFO, dict)
    end

    def load_config_detail
      self.load_config
    end
  end
end
