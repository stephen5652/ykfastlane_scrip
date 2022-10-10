require 'fastlane'
require 'yaml'

module YKAppleModule
  module AccountHelper
    require 'Spaceship'

    class AccountClient
      attr_accessor :account_client

      def initialize
        @account_client = nil
      end

      def self.login(username, password)
        Fastlane::UI.message("Login to App Store Connect (#{username})")
        credentials = CredentialsManager::AccountManager.new(user: username, password: password)
        client = Spaceship::ConnectAPI.login(credentials.user, credentials.password, use_portal: true, use_tunes: false, skip_select_team: true)
        Fastlane::UI.message("Login successful, client:#{client.class}:#{client}")
        result = self.new()
        result.account_client = client
        result
      end

      def select_team_profile(bundle_id_arr)
        '' '
        1. 获取所有teamId
        2. 遍历teamId, 切换到对应teamId
        3. 遍历bundle_id_arr,使用app_bundleId筛选对应的profile
        4. 记录profile信息，并下载profile
        5. 返回profile信息
        ' ''
        team_to_bundleIds = self.select_bundle_id(bundle_id_arr)

        all_loaded_profile = []
        team_to_bundleIds.each_pair do |t, b|
          puts("Loading team[#{t}]--profiles#{b}")
          profile_arr = self.load_profiles(t, b)
          all_loaded_profile += profile_arr
        end

        all_loaded_profile
      end

      def select_bundle_id(dest_bundle_arr = [])
        teams = self.account_client.portal_teams
        result_map = {}
        teams.each do |t|
          teamId = t["teamId"]
          self.account_client.select_team(portal_team_id: teamId)
          #Spaceship::PortalClient
          portal_client = self.account_client.portal_client
          team_info = portal_client.team_information
          if team_info["status"] == "expired"
            Fastlane::UI.important("team[#{t["name"]} -- #{teamId}] is expired, skip it")
            next
          end

          bundle_id_arr = Spaceship::ConnectAPI::BundleId.all(client: self.account_client)
          filted = bundle_id_arr
          if dest_bundle_arr.length > 0
            filted = bundle_id_arr.find_all do |s|
              dest_bundle_arr.include?(s.identifier)
            end
          end
          result_map[teamId] = filted unless filted.blank?
        end

        puts("select_bundle_id_result:#{result_map}")
        result_map
      end

      def load_profiles(team_id, bundle_ids)

        self.account_client.select_team(portal_team_id: team_id)
        result = []
        bundle_ids.each do |one|
          find_result = Spaceship::ProvisioningProfile.find_by_bundle_id(bundle_id: one.identifier, mac: false, sub_platform: nil)
          #Spaceship::Portal::ProvisioningProfile::Development

          dir = File.expand_path(File.join(Dir.home, 'Desktop', 'TestProfiles'))
          if File.exist?(dir) == false
            FileUtils.mkdir(dir)
          end

          find_result.each do |one_profile|

            des_path = File.join(dir, "#{one_profile.name}_#{one_profile.uuid}.mobileprovision")

            File.write(des_path, one_profile.download())
            #Spaceship::Base::DataHash
            pro_info = one_profile.raw_data.to_h
            pro_info[:file_path] = des_path
            result.append(pro_info)
            #Spaceship::ProvisioningProfile
            Fastlane::UI.important("Load profile finish[#{one_profile.raw_data["appId"]["identifier"]}]:#{one_profile.name} -- #{one_profile.uuid}")
          end
        end

        result
      end

    end
  end
end
