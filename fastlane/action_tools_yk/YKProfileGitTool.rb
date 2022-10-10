module YKProfileModule
  module YKProfileGitExecute
    module YKProfileGitHelper
      YK_CONFIG_PROFILE_LOCAL_ROOT_DIR = File.expand_path(File.join(Dir.home, '.ykfastlane_config', 'apple_certificates'))

      YK_CONFIG_PROFILE_LOCAL_DIR = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificateProfiles', 'profile_files')
      YK_CONFIG_CERTIFICATE_LOCAL_DIR = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificateProfiles', 'certificate_files')

      YK_CONFIG_INFO_YML_PROFILE = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificateProfiles', 'profile_info_list.yml')
      YK_CONFIG_INFO_YML_CERTIFICATE = File.join(YK_CONFIG_PROFILE_LOCAL_ROOT_DIR, 'certificateProfiles','certificate_info_list.yml')

      YK_CONFIG_GIT_YAML = File.expand_path(File.join(Dir.home, '.ykfastlane_config', 'profile_git_info.yml'))
    end

    include YKProfileGitHelper

    require 'fileutils'
    require 'fastlane'
    require 'git'
    require 'yaml'
    require_relative 'YKYmlTool'

    include YKYmlModule

    def self.update_profile_info(name, info)
      path = YKProfileGitHelper::YK_CONFIG_INFO_YML_PROFILE
      YKYmlModule.update_yml_yk(path, name, info)
    end

    def self.add_file(dest_dir, path)
      name = File.basename(path)
      if File.exist?(dest_dir) == false
        FileUtils.mkdir_p(dest_dir)
      end

      dest_path = File.join(dest_dir, name)
      FileUtils.cp_r(path, dest_path, remove_destination: true)
      name
    end

    def self.add_profile(path)
      dest_dir = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_DIR
      self.add_file(dest_dir, path)
    end

    def self.add_certificate(path)
      dest_dir = YKProfileGitHelper::YK_CONFIG_CERTIFICATE_LOCAL_DIR
      self.add_file(dest_dir, path)
    end

    def self.update_certificate_info(name, info)
      path = YKProfileGitHelper::YK_CONFIG_INFO_YML_CERTIFICATE
      YKYmlModule.update_yml_yk(path, name, info)
    end

    def self.load_profile_remote(remote)
      dest_path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR
      if File.exist?(dest_path)
        Fastlane::UI.important("Local Path existed, remove it first:#{dest_path}")
        FileUtils.rm(dest_path, force: true)
      end

      begin
        puts "start clone:#{remote}"
        cloneResult = Git::clone(remote, dest_path, :log => Logger.new(Logger::Severity::INFO))
        puts "clone_result:#{cloneResult}"
      rescue Git::GitExecuteError => e
        puts "clone failed:#{e}"
        return false #任务失败
      end

      return true
    end

    def self.sync_profile_remote()
      path = YKProfileGitHelper::YK_CONFIG_PROFILE_LOCAL_ROOT_DIR
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

      return true
    end

    def self.profile_commit(msg)
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
        puts "git clean, work success"
        git.push('origin', curbranch)
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

    def self.get_certificate_info_dict()
      YKYmlModule.load_yml_yk(YKProfileGitHelper::YK_CONFIG_INFO_YML_CERTIFICATE)
    end

    def self.get_profile_info_dict()
      YKYmlModule.load_yml_yk(YKProfileGitHelper::YK_CONFIG_INFO_YML_PROFILE)
    end

  end

end
