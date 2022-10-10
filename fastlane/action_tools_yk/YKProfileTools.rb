require 'fastlane'

module YKProfileModule

  module YKProfileEnv
    YK_CONFIG_ROOT_DIR = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config'))
    YK_CONFIG_PROFILE_YAML = File.join(YK_CONFIG_ROOT_DIR, 'profile.yml')

    require 'openssl'
    require 'plist'
    require 'yaml'
    require_relative 'YKYmlTool'

    include YKYmlModule

    def self.load_profile_yml()
      config_path = YKProfileModule::YKProfileEnv::YK_CONFIG_PROFILE_YAML
      yml = YKYmlModule.load_yml_yk(config_path)
      puts("yml[#{yml.class}]:#{yml.to_json}")
      puts("profile_config_path:#{config_path}")
      yml
    end

    def self.check_profile_type(plist_content)
      '' '
        1. ProvisionedDevices  ---> debug / ad-hoc
            1.1 get_task_allow => true  --> development
            1.2 get_task_allow => false ---> ad-hoc
        2. ProvisionsAllDevices => true ---> enterprise
        3.  ---> appstore
        ' ''
      result = ""
      devices = plist_content["ProvisionedDevices"]
      if devices.blank? == false # debug / ad-hoc
        task_allow = plist_content["Entitlements"]["get-task-allow"]
        if task_allow == false # ad-hoc
          result = "ad-hoc"
        else
          # development
          result = "development"
        end
      else
        # enterprise / appstore
        all_devices = plist_content["ProvisionsAllDevices"]
        if all_devices != nil && all_devices == true
          result = "enterprise"
        else
          result = "appstore"
        end
      end

      plist_content["method_type"] = result
      plist_content
    end

    def self.analysisProfile(path)
      asn1 = OpenSSL::ASN1.decode_all(File.binread(path))
      plist = asn1[0].value[1].value[0].value[2].value[1].value[0].value
      plist_content = Plist.parse_xml(plist)
      plist_content = self.check_profile_type(plist_content)
      plist_content
    end

    # @return [String] The UUID of the given provisioning profile
    def self.uuid(path, keychain_path = nil)
      info = analysisProfile(path)
      self.uuid_from_info(info)
    end

    def self.uuid_from_info(info)
      info["UUID"]
    end

    def self.bundle_id(path)
      info = analysisProfile(path)
      self.bunlde_id_from_info(info)
    end

    def self.bundle_id_from_info(info)
      elements = info["Entitlements"]
      bundle_id = elements["application-identifier"]
      bundle_id_prefix_arr = info["ApplicationIdentifierPrefix"]
      bundle_id_prefix_arr.each do |one|
        bundle_id = bundle_id.gsub("#{one}.", "")
      end

      bundle_id
    end

    def self.method_type(path)
      info = analysisProfile(path)
      self.method_type_from_info(info)
    end

    def self.method_type_from_info(info)
      info["method_type"]
    end

    def self.profile_extension(path, keychain_path = nil)
      ".mobileprovision"
    end

    def self.profiles_path
      path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/"
      # If the directory doesn't exist, create it first
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end

      return path
    end

    def self.profile_filename(path, keychain_path = nil)
      basename = uuid(path, keychain_path)
      basename + profile_extension(path, keychain_path)
    end

    # Installs a provisioning profile for Xcode to use
    def self.install(path, keychain_path = nil)
      Fastlane::UI.important("Installing provisioning profile:#{path}")
      destination = File.join(self.profiles_path, self.profile_filename(path, keychain_path))
      Fastlane::UI.important("destination:#{destination}")
      if path != destination
        # copy to Xcode provisioning profile directory
        FileUtils.copy(path, destination)
        if File.exist?(destination)
          Fastlane::UI.important("Install profile success:#{path}")
        else
          Fastlane::UI.important("Failed installation of provisioning profile at location: '#{destination}'")
        end
      end

      destination
    end

    def self.keychain_path(keychain_name)
      name = keychain_name.sub(/\.keychain$/, "")
      possible_locations = [
        File.join(Dir.home, 'Library', 'Keychains', name),
        name
      ].map { |path| File.expand_path(path) }

      # Transforms ["thing"] to ["thing-db", "thing.keychain-db", "thing", "thing.keychain"]
      keychain_paths = []
      possible_locations.each do |location|
        keychain_paths << "#{location}-db"
        keychain_paths << "#{location}.keychain-db"
        keychain_paths << location
        keychain_paths << "#{location}.keychain"
      end

      keychain_path = keychain_paths.find { |path| File.file?(path) }
      UI.user_error!("Could not locate the provided keychain. Tried:\n\t#{keychain_paths.join("\n\t")}") unless keychain_path
      keychain_path
    end

    def self.install_profiles(profiles_arr)
      profiles_arr.each do |one|
        YKProfileEnv.install(one, self.keychain_path("login"))
      end
    end

    def self.install_one_profile(profile_path)
      if File.exist?(profile_path)
        YKProfileEnv.install(profile_path, self.keychain_path("login"))
        info = self.analysisProfile(profile_path)
        self.update_archive_profile_info_from_info(info)
      end
    end

    def self.update_archive_profile_info_from_info(info)
      uuid = YKProfileEnv.uuid_from_info(info)
      bundle_id = YKProfileEnv.bundle_id_from_info(info)
      method = YKProfileEnv.method_type_from_info(info)
      YKProfileEnv.update_archive_profile_info(uuid, method, bundle_id)
    end

    def self.update_archive_profile_info(uuid, method, bundle_id)
      dict = { method => uuid }
      path = YKProfileModule::YKProfileEnv::YK_CONFIG_PROFILE_YAML
      YKYmlModule.update_yml_dict_value_yk(path, bundle_id, dict)
    end

    def self.find_archive_profile_uuid(bundle_id, method)
      path = YKProfileModule::YKProfileEnv::YK_CONFIG_PROFILE_YAML
      dict = YKYmlModule.load_yml_value_yk(path, bundle_id)
      if dict.blank? == false
        return dict[method]
      else
        return ""
      end

    end

  end
end
