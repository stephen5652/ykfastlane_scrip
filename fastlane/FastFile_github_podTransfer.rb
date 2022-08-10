#!/usr/bin/env ruby

=begin
1. 在~/GitHubComponents下clone对应文件夹
2. 同步移卡仓库和github仓库
3. 检查tags,有三类：移卡仓库的， github仓库的， github仓库未迁移的
4. 针对未迁移的tag,创建分支，修改podspec文件，创建tag, 入库
=end
import "./pod_transfer_wxwork_notifier.rb"

default_platform(:ios)

$script_run_path_pod = ""
$path_github_components = File.expand_path("~/GitHubComponents")
$remote_ykname = "origin_yk"

class YKGitHubPods
  attr_accessor :remote_github
  attr_accessor :remote_ykgitlab

  attr_accessor :component_name
  attr_accessor :component_dir

  attr_accessor :work_path

  attr_accessor :tags_all
  attr_accessor :tags_github_extra
  attr_accessor :tags_moving
  attr_accessor :tags_yeah_private
  attr_accessor :destination_versions

  attr_accessor :access_token

  def initialize(work_path, remote_github, remote_ykgitlab, versionsStr)
    self.work_path = work_path
    self.remote_github = remote_github
    self.remote_ykgitlab = remote_ykgitlab
    puts "versions str:#{versionsStr}"
    self.destination_versions = []
    if versionsStr.blank? == false
      versionsStr.split(" ").each do |oneVersion|
        self.destination_versions << oneVersion unless oneVersion.blank?
      end
    end

    puts "destination versions:#{self.destination_versions}"

    project_name = File.basename(remote_github, ".*")
    project_dir = File.expand_path(File.join($path_github_components, project_name))
    self.component_name = project_name
    self.component_dir = project_dir

    puts "work_path:#{work_path}"
    puts "component_name:#{self.component_name}"
    puts "component_path:#{self.component_dir}"
    puts "remote_github:#{self.remote_github}"
    puts "remote_ykgitlab:#{self.remote_ykgitlab}"
  end
end

desc "" "
    迁移github三方库到移开gitlab.
    描述: 
    1. 需要在移开gitlab创建一个同名的git仓库.

    参数: 
      orignal_url: [必需]
      ykgitlab_url:[必需]
      versions:[非必需] 迁移的目标版本，多个的时候用空格\' \'隔开， 默认遍历尝试迁移所有的版本，比较耗时
      wxwork_access_token:[非必需] 用于将任务结果传给企业微信

    command example: ykfastlane github_pod_transfer orignal_url:'https://github.com/AFNetworking/AFNetworking.git' ykgitlab_url:'http://gitlab.xxxxx.com/App/iOS/GitHubComponents/AFNetworking.git' versions:\"1.0.0 1.3.4 1.2.5\"
" ""
lane :github_pod_transfer do |options|
  puts "git hub pod transfer:#{options}"
  $script_run_path_pod = options[:script_run_path] unless options[:script_run_path].blank?

  UI.user_error!("orignal_url is empty") if options[:orignal_url].blank?
  UI.user_error!("ykgitlab_url is empty") if options[:ykgitlab_url].blank?
  podObj = YKGitHubPods.new($script_run_path_pod, options[:orignal_url], options[:ykgitlab_url], options[:versions])
  podObj.access_token = options[:wxwork_access_token]
  clone_project_func(podObj)
  github_git_tags_list_func(podObj)
  transfer_versions(podObj)
end

"" "创建文件夹" ""

def clone_project_func(podObj)
  if File.exist?(podObj.component_dir) == false
    puts "start clone to: #{$path_github_components} --verbose"
    cmd = ["git clone #{podObj.remote_github} #{podObj.component_dir} --verbose"]
    cmd << " && cd #{podObj.component_dir}"
    cmd << " && git remote add #{$remote_ykname} #{podObj.remote_ykgitlab}"
    cmd << " && git push #{$remote_ykname} --verbose"
    cmd_str = cmd.compact.join(" ")
    puts "cmd:#{cmd_str}"
    Actions.sh(cmd_str, log: true)
  else
    cmd = [" cd #{podObj.component_dir}"]
    cmd << " && git remote"
    cmd_str = cmd.compact.join(" ")
    # cmd << " && git remote add #{$remote_ykname} #{podObj.remote_ykgitlab}"
    # cmd << " && git add. && git reset --hard && git pull --verbose"
    # cmd_str = cmd.compact.join(" ")
    puts "cmd:#{cmd_str}"
    remoteArr = Actions.sh(cmd_str, log: true).split(/\n/)
    if remoteArr.include? $remote_ykname
      cmd = [" cd #{podObj.component_dir}"]
      cmd << " && git add . && git reset --hard && git checkout master"
      cmd << " && git remote remove #{$remote_ykname}"
      cmd << " && git remote add #{$remote_ykname} #{podObj.remote_ykgitlab}"
      cmd << " && git push #{$remote_ykname} --verbose"
      cmd_str = cmd.compact.join(" ")
      Actions.sh(cmd_str, log: true, error_callback: lambda do |value|
      end)
    end
  end

end

"" "检测tag" ""

def github_git_tags_list_func(podObj)
  tags = git_tag_list_yk(work_path: podObj.component_dir)
  podObj.tags_all = tags[:GIT_TAG_LIST_YK_TAGS_LIST]
  podObj.tags_github_extra = tags[:GIT_TAG_LIST_YK_TAGS_GITHUB_EXTRA]
  podObj.tags_yeah_private = tags[:GIT_TAG_LIST_YK_TAGS_YKVERSION]
  tags = podObj.tags_github_extra
  if podObj.destination_versions.count != 0
    tags = []
    podObj.tags_github_extra.each do |ont_tag|
      podObj.destination_versions.each do |one_des|
        if ont_tag.include? one_des
          tags << ont_tag
        end
      end
    end
  end
  podObj.tags_moving = tags
end

"" "修改tag" ""

def transfer_versions(podObj)
  tags = podObj.tags_moving
  UI.important("will transfer versions:#{tags}")
  # one_version = tags.first
  # for one_version in tags
  # pod_transfer_version(
  #   version_name: '4.0.1',
  #   project_path: podObj.component_dir,
  #   remote_destioation_url: podObj.remote_ykgitlab,
  #   remote_destioation_name: $remote_ykname,
  #   repo_name: "xxxxx-app-ios-ykgithubspecs",
  # )

  tags.each do |one_version|
    result = pod_transfer_version(
      version_name: one_version,
      project_path: podObj.component_dir,
      remote_destioation_url: podObj.remote_ykgitlab,
      remote_destioation_name: $remote_ykname,
      repo_name: "xxxx-app-ios-ykgithubspecs",
    )
  end

  failedVersions = lane_context[:POD_TRANSFER_VERSION_FAILED]
  successVersions = lane_context[:POD_TRANSFER_VERSION_SUCCESS]
  UI.important("failed Versions:#{failedVersions}")
  UI.important("success Versions:#{successVersions}")

  transfer_result = YKWxwork_podTransferResult.new(podObj.access_token)
  transfer_result.pod_name = podObj.component_name
  transfer_result.versions_all = podObj.tags_all
  transfer_result.versions_moving = podObj.tags_moving
  transfer_result.versions_success = successVersions.blank? ? [] : successVersions
  transfer_result.versions_failed = failedVersions.blank? ? [] : failedVersions
  sendWxworkMessage(transfer_result)
  # if successVersions.count == 0
  #   UI.user_error!("no version successed!!")
  # end
end
