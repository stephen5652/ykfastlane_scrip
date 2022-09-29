module Fastlane
  module Actions
    module SharedValues
      YK_GIT_CHANGES = :YK_GIT_CHANGES
    end

    module YKProfileHelper
      PATH_CONFIG_ROOT_DIR = File.expand_path(File.join(Dir.home, '.ykfastlane_config/archive_config'))
      PATH_CONFIG_PROFILE_DETAIL = File.join(PATH_CONFIG_ROOT_DIR, 'profile.yml')
      require 'openssl'
      require 'plist'
      require 'yaml'

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
          else # development
            result = "development"
          end
        else
          # enterprise / appstore
          all_devices = plist_content["ProvisionsAllDevices"]
          if all_devices != nil  && all_devices == true
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
        dict = analysisProfile(path)
        dict["UUID"]
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
          unless File.exist?(destination)
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
          Fastlane::Actions::YKProfileHelper.install(one, self.keychain_path("login"))
        end
      end

      def self.update_profile_info(uuid, method, bundle_id)
        Fastlane::UI.important("profile--uuid:#{uuid}\tbundle_id:#{bundle_id}\tmethod:#{method}")
        path = YKProfileHelper::PATH_CONFIG_PROFILE_DETAIL
        if File.exist?(path) == false
          FileUtils.makedirs(File.dirname(path)) if File.exist?(File.dirname(path)) == false
          f = File.new(path, "w+")
          f.close
        end

        f = File.open(path, "r")
        yml = YAML.load(f, symbolize_names: false)
        f.close
        yml = {} if yml == false #空yml的时候， yml = false
        yml

        dict = yml[bundle_id]
        dict = {} if dict == nil || dict.blank?
        dict[method] = uuid
        yml[bundle_id] = dict

        Fastlane::UI.important("profile_config:#{yml}")

        f = File.open(path, "w+")
        YAML.dump(yml, f, symbolize_names: false)
        f.close
      end
    end

    class AnalysisMobileprofileYkAction < Action
      include Fastlane::Actions::YKProfileHelper

      def self.run(params)
        Fastlane::UI.important("paramas:#{params.values}")
        profile = params[:profile_path]
        Fastlane::Actions::YKProfileHelper.install_profiles([profile])

        info = Fastlane::Actions::YKProfileHelper.analysisProfile(profile)
        puts("profile_info:#{info}")
        elements = info["Entitlements"]
        bundle_id = elements["application-identifier"]
        bundle_id_prefix_arr = info["ApplicationIdentifierPrefix"]
        bundle_id_prefix_arr.each do |one|
          bundle_id = bundle_id.gsub("#{one}.", "")
        end
        uuid = info["UUID"]
        method = info["method_type"]
        Fastlane::Actions::YKProfileHelper.update_profile_info(uuid, method, bundle_id)
      end

      def self.description
        "解析，并安装 .mobileprofile"
      end

      def self.details
        "根据默认配置，寻找到对应的profile"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :profile_path,
                                       description: "ios bundle identifier", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error("No bundle identifier") unless (value and not value.empty?)
                                       end),
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        {
          :profile_uuid => "profile_uuid",
          :export_method => "export_method",
          :profile_path => "profile_path"
        }
      end

      def self.authors
        ["stephen5652@126.com/stephenchen"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

    end
  end
end
