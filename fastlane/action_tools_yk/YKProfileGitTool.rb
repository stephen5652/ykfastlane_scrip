module YKProfileModule
  module YKProfileGitHelper
    YK_CONFIG_PROFILE_LOCAL_ROOT_DIR = File.expand_path(File.join(Dir.home, '.ykfastlane_config', 'apple_certificates', 'certificateProfiles'))

    YK_CONFIG_PROFILE_LOCAL_DIR = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'profile_files')
    YK_CONFIG_CERTIFICATE_LOCAL_DIR = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificate_files')

    YK_CONFIG_INFO_YML_PROFILE = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'profile_info_list.yml')
    YK_CONFIG_INFO_YML_CERTIFICATE = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificate_info_list.yml')

    YK_CONFIG_GIT_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config', 'profile_git_info.yml'))

    def self.add_file(dest_dir, path)
      path = File.expand_path(path)
      name = File.basename(path)
      if File.exist?(dest_dir) == false
        FileUtils.mkdir_p(dest_dir)
      end

      dest_path = File.join(dest_dir, name)
      FileUtils.cp_r(path, dest_path, remove_destination: true)
      name
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

  end

  require 'fastlane'

  module YKProfileGitExecute

    include YKProfileGitHelper

    require 'fileutils'
    require 'git'
    require 'yaml'
    require_relative 'YKYmlTool'

    include YKYmlModule

    def self.update_profile_info(name, info)
      path = YKProfileGitHelper::YK_CONFIG_INFO_YML_PROFILE
      YKYmlModule.update_yml_yk(path, name, info)
    end

    def self.add_profile(path)
      dest_dir = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_DIR
      YKProfileGitHelper.add_file(dest_dir, path)
    end

    def self.update_certificate_info(name, info)
      path = YKProfileGitHelper::YK_CONFIG_INFO_YML_CERTIFICATE
      YKYmlModule.update_yml_yk(path, name, info)
    end

    def self.load_profile_remote()
      remote = self.get_profile_env_git_remote
      if remote.blank?
        Fastlane::UI.important("Not config profile & certificate remote")
        return false
      end

      dest_path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR
      if File.exist?(dest_path)
        Fastlane::UI.important("Local Path existed, remove it first:#{dest_path}")
        FileUtils.rm_r(dest_path, force: true)
      end

      begin
        Fastlane::UI.message("start clone:#{remote}")
        cloneResult = Git::clone(remote, dest_path, :log => Logger.new(Logger::Severity::INFO))
        puts "clone_result:#{cloneResult}"
      rescue Git::GitExecuteError => e
        Fastlane::UI.message("clone failed:#{e}")
        return false #任务失败
      end

      Fastlane::UI.message("Clone success !!")
      return true
    end

    def self.existed_profile_certificate()
      dest_path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR
      result = File.exist?(dest_path)
      result
    end

    def self.sync_profile_remote()
      path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR

      if File.exist?(path) == false
        return self.load_profile_remote()
      end

      Fastlane::UI.important("Git pull certificate & profile")
      begin
        git = Git::open(path)
        git.add()
        git.reset_hard()
        curbranch = git.current_branch
        git.pull('origin', curbranch)
      rescue Git::GitExecuteError => e
        puts "pull remote failed:#{e}"
        return false #任务失败
      end

      Fastlane::UI.message("Git pull certificate & profile successfully")
      return true
    end

    def self.git_commit(msg)
      puts("\n")
      Fastlane::UI.important("Git start commit")
      path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR
      git = Git::open(path)
      git.add()
      curbranch = git.current_branch
      begin
        git.commit("update:#{msg}")
      rescue Git::GitExecuteError => e
        puts "commit update execption:#{e}"
      end

      status = git.status()
      if status.untracked.count != 0 || status.changed.count != 0
        puts "git not clean, work failed"
        return false
      else
        puts "git clean, start push"

        begin
          git.push('origin', curbranch)
        rescue Git::GitExecuteError => e
          puts "git push execption:#{e}"
        end

        Fastlane::UI.important("Git push successfully")
        return true
      end
    end

    def self.update_profile_env_git_info(remote)
      path = YKProfileGitHelper::YK_CONFIG_GIT_YAML
      YKYmlModule.update_yml_yk(path, :profile_remote, remote)
    end

    def self.get_profile_env_git_remote()
      path = YKProfileGitHelper::YK_CONFIG_GIT_YAML
      remote_url = YKYmlModule.load_yml_value_yk(path, :profile_remote)
      remote_url
    end

    def self.get_profile_certificate_git_info()
      YKYmlModule.load_yml_yk(YKProfileGitHelper::YK_CONFIG_GIT_YAML)
    end

    def self.get_certificate_info_dict()
      YKYmlModule.load_yml_yk(YKProfileGitHelper::YK_CONFIG_INFO_YML_CERTIFICATE)
    end

    def self.get_profile_info_dict()
      YKYmlModule.load_yml_yk(YKProfileGitHelper::YK_CONFIG_INFO_YML_PROFILE)
    end

    def self.get_profile_path(info)
      name = info[:file_name]
      return "" if name.blank?
      path = File.expand_path(File.join(YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_DIR, name))
      path = "" unless File.exist?(path)
      path
    end

  end

  module YKCertificateP12Execute
    include YKProfileGitHelper

    K_CER_INFO_KEY_NAME = :file_name
    K_CER_INFO_KEY_PASSWORD = :password

    def self.analysis_p12(cer_path, cer_pass)
      p12 = OpenSSL::PKCS12.new(File.read(cer_path), cer_pass)
      cer = p12.certificate # OpenSSL::X509::Certificate
      arr = cer.subject.to_a # OpenSSL::X509::Name

      uid = arr.select { |name, _, _| name == 'UID' }.first[1]
      cn = arr.select { |name, _, _| name == 'CN' }.first[1]
      ou = arr.select { |name, _, _| name == 'OU' }.first[1]
      o = arr.select { |name, _, _| name == 'O' }.first[1]
      c = arr.select { |name, _, _| name == 'C' }.first[1]

      file_name = File.basename(cer_path)
      result = {
        :c => c,
        :o => o,
        :ou => ou,
        :cn => cn,
        :uid => uid,
        K_CER_INFO_KEY_NAME => file_name,
        K_CER_INFO_KEY_PASSWORD => cer_pass,
      }
      result
    end

    def self.install_one_certificate(file_path, password)
      password_part = " -P #{password}"
      command = "security import #{file_path} -k #{YKProfileGitHelper.keychain_path("login")}"
      command << password_part
      command << " -T /usr/bin/codesign" # to not be asked for permission when running a tool like `gym` (before Sierra)
      command << " -T /usr/bin/security"
      command << " -T /usr/bin/productbuild" # to not be asked for permission when using an installer cert for macOS
      command << " -T /usr/bin/productsign" # to not be asked for permission when using an installer cert for macOS

      sensitive_command = command.gsub(password_part, " -P ********")
      puts("\n")
      Fastlane::UI.message("install_certificate:#{sensitive_command}")
      Open3.popen3(command) do |stdin, stdout, stderr, thrd|
        Fastlane::UI.important(stdout.read.to_s)

        # Set partition list only if success since it can be a time consuming process if a lot of keys are installed
        if thrd.value.success?
          Fastlane::UI.important("install one p12 success:#{file_path}")
        else
          # Output verbose if file is already installed since not an error otherwise we will show the whole error
          err = stderr.read.to_s.strip
          if err.include?("SecKeychainItemImport") && err.include?("The specified item already exists in the keychain")
            Fastlane::UI.important("'#{File.basename(path)}' is already installed on this machine")
          else
            Fastlane::UI.user_error!("error:#{err}")
          end
        end
      end
    end

    def self.install_certificates_info_map(map)
      map.each do |key, info|
        file_path = File.join(YKProfileGitHelper::YK_CONFIG_CERTIFICATE_LOCAL_DIR, info[K_CER_INFO_KEY_NAME])
        password = info[K_CER_INFO_KEY_PASSWORD]
        if File.exist?(file_path)
          self.install_one_certificate(file_path, password)
        else

        end
      end
    end

    def self.add_one_certificate(path)
      dest_dir = YKProfileGitHelper::YK_CONFIG_CERTIFICATE_LOCAL_DIR
      name = YKProfileGitHelper.add_file(dest_dir, path)
      name
    end

    def self.get_certificate_path(info)
      name = info[K_CER_INFO_KEY_NAME]
      return "" unless name.blank?
      path = File.expand_path(File.join(YKProfileGitHelper::YK_CONFIG_CERTIFICATE_LOCAL_DIR, name))
      path = "" unless File.exist?(path)
      path
    end

    def self.get_certificate_password(info)
      info[YKProfileGitHelper::K_CER_INFO_KEY_PASSWORD]
    end

  end

end
