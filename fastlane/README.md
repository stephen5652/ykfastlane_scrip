fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### archive_pgyer

```sh
[bundle exec] fastlane archive_pgyer
```


    打iOS测试包,并上传蒲公英,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      pgyer_api: [必需] 蒲公英平台api_key
      pgyer_user[必需] 蒲公英平台 user_key
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_pgyer scheme:ShuabaoQ pgyer_api:"123456" pgyer_user:"123456" wxwork_access_token:"wxworktokem" note:"note" xcworkspace:"~/Desktop/ShuaBao" cocoapods:1 flutter_directory:"flutter_directory"


### archive_fire

```sh
[bundle exec] fastlane archive_fire
```


    打iOS测试包,并上传Fir,发送结果给企业微信群
    参数: 
      scheme: [必需] 
      fir_api_token: [必需] Fir平台api token
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_fire scheme:ShuabaoQ fir_api_token:"fir_api_token" wxwork_access_token:"wxworktokem" note:"note" xcworkspace:"~/Desktop/ShuaBao" cocoapods:1 flutter_directory:"flutter_directory"


### yk_install_mobileprovision_enterprise

```sh
[bundle exec] fastlane yk_install_mobileprovision_enterprise
```


    安装mobileprovision 文件.
    描述: 
    1.需要创建一个git仓库, 仓库中有一个 provision_files_enterprise 文件夹;
    2. provision_files_enterprise 文件夹里面放置所有的描述文件;
    3. 该指令需要在provision_files_enterprise文件夹的上级的根目录执行.

    该指令没有参数.

    command example: ykfastlane yk_install_mobileprovision_enterprise
 

### yk_install_cetificates_enterprise

```sh
[bundle exec] fastlane yk_install_cetificates_enterprise
```


    安装 certificate 文件.
    描述: 
    1. 需要创建一个git仓库, 仓库中有一个 certificate_files_enterprise 文件夹;
    2. certificate_files_enterprise 文件夹里面放置所有的证书文件;
    3. 所有的证书只能有一个密码
    4. 该指令需要在provision_files_enterprise文件夹的上级的根目录执行.

    参数: 
      password_keychain: [必需] 证书安装在 "登录" 的keychain项, 需要解锁keychain, 此字段一般是用户的开机密码.
      password_cer: [非必须] 如果证书有密码, 则需要传密码

    command example: ykfastlane yk_install_cetificates_enterprise password_cer:123456 password_keychain:123456
 

### re_upload_pgyer

```sh
[bundle exec] fastlane re_upload_pgyer
```


    reupload ipa to pgyer
    options are: ipa[require], note[optional], last_log[optional], pgyer_api[optional], pgyer_user[optional] wxwork_access_token[require]

    command example: ykfastlane re_upload_pgyer pgyer_api:"1234" pgyer_user:"123456" note:"reupload ipa" last_log:"~/abc" wxwork_access_token:"wxwork_key"


### re_upload_fir

```sh
[bundle exec] fastlane re_upload_fir
```


    reupload ipa to fir
    options are: fir_api_token[required], last_log[optional] wxwork_access_token[require] note[optional]

    command example: ykfastlane re_upload_fir fir_api_token:"1234" wxwork_access_token:"wxwork_key" last_log:"~/xx/x/directory" note:"reupload"


### clear_buile_temp

```sh
[bundle exec] fastlane clear_buile_temp
```



### test_lane

```sh
[bundle exec] fastlane test_lane
```

private lane, cannot be used. Just used for developing to testing some action.

### github_pod_transfer

```sh
[bundle exec] fastlane github_pod_transfer
```


    迁移github三方库到移开gitlab.
    描述: 
    1. 需要在移开gitlab创建一个同名的git仓库.

    参数: 
      orignal_url: [必需]
      ykgitlab_url:[必需]
      versions:[非必需] 迁移的目标版本，多个的时候用空格' '隔开， 默认遍历尝试迁移所有的版本，比较耗时
      wxwork_access_token:[非必需] 用于将任务结果传给企业微信

    command example: ykfastlane github_pod_transfer orignal_url:'https://github.com/AFNetworking/AFNetworking.git' ykgitlab_url:'http://gitlab.xxxxx.com/App/iOS/GitHubComponents/AFNetworking.git' versions:"1.0.0 1.3.4 1.2.5"


----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
