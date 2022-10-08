require 'fastlane'
require 'yaml'

module YKProfileModule
  module YKProfileEnv
    YK_CONFIG_GIT_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config/git_info.yml'))
    YK_CONFIG_PROFILE_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config/profile.yml'))
    def self.profile_config_path_yk()
      result = YKProfileModule::YKProfileEnv::YK_CONFIG_PROFILE_YAML
      result
    end

    def self.load_profile_yml()
      config_path = YKProfileEnv.profile_config_path_yk()
      if File.exist?(config_path) == false
        return {}
      end

      f = File.open(config_path, 'r')
      yml = YAML.load(f, symbolize_names: false)
      f.close
      if yml == false
        yml = {}
      end
      puts("yml[#{yml.class}]:#{yml.to_json}")
      puts("profile_config_path:#{config_path}")
      yml
    end
  end
end
