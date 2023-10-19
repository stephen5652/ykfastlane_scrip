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
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.
      export: [可选] 包的类型, 包的类型, app-store, validation,ad-hoc, package, enterprise, development, developer-id, mac-application, 默认为enterprise

    command example: ykfastlane archive_pgyer scheme:ShuabaoQ pgyer_api:"123456" pgyer_user:"123456" wxwork_access_token:"wxworktokem" note:"note" xcworkspace:"~/Desktop/ShuaBao" cocoapods:1 flutter_directory:"flutter_directory"


### archive_fir

```sh
[bundle exec] fastlane archive_fir
```


    打iOS测试包,并上传Fir,发送结果给企业微信群
    参数:
      scheme: [必需]
      fir_api_token: [必需] Fir平台api token
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [必需] 企业微信机器人 webhook中的key字段

      note: [可选] 测试包发包信息
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      export: [可选] 包的类型, 包的类型, app-store, validation,ad-hoc, package, enterprise, development, developer-id, mac-application, 默认为enterprise
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.

    command example: ykfastlane archive_fir scheme:ShuabaoQ fir_api_token:"fir_api_token" wxwork_access_token:"wxworktokem" note:"note" xcworkspace:"~/Desktop/ShuaBao" cocoapods:1 flutter_directory:"flutter_directory"


### archive_tf

```sh
[bundle exec] fastlane archive_tf
```


    打iOS测试包,并上传TF,发送结果给企业微信群
    参数:
      scheme: [必需]
      user_name: [必需] apple id
      pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
      yk_ipa_upload_api[可选] 私有ipa分发地址

      note: [可选] 测试包发包信息
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数
      xcworkspace: [可选] .xcworkspace 文件相对于指令工作目录的相对路径
      cocoapods: [可选] 0 / 1  是否需要执行pod install, 默认不执行pod install 指令
      flutter_directory: [可选] 如果有flutter混编, 此参数是 flutter项目的相对路径.
      wxwork_access_token: [可选] 企业微信机器人


    command example: ykfastlane archive_tf scheme:ShuabaoQ user_name:"xxxx.com" pass_word:"xxx-xxx-xxx-xxx" wxwork_access_token:"wxworktokem" note:"note" xcworkspace:"~/Desktop/ShuaBao" cocoapods:1 flutter_directory:"flutter_directory"


### clean_product_directory

```sh
[bundle exec] fastlane clean_product_directory
```


   删除iOS打包产物文件夹
   参数:
   wxwork_access_token: [可选] 企业微信机器人


### upload_ipa_to_tf

```sh
[bundle exec] fastlane upload_ipa_to_tf
```


    上传TF,发送结果给企业微信群
    参数:
      ipa: [必需] ipa文件绝对路径
      user_name: [必需] apple id
      pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
      yk_ipa_upload_api[可选] 私有ipa分发地址
      wxwork_access_token: [可选] 企业微信机器人
      note: [可选] TF包发包信息,用以通知相关开发
      branch_name: [可选] 分支名称，因为可能git只是浅拷贝，在项目目录使用 git 指令获取不到当前分支，所以提供了这个参数

    command example: ykfastlane upload_ipa_to_tf ipa:"xxxx/xxx/xx.ipa" user_name:"xxxx.com" pass_word:"xxx-xxx-xxx-xxx" wxwork_access_token:"wxworktokem" note:"note"


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


### clear_build_temp

```sh
[bundle exec] fastlane clear_build_temp
```



### test_lane

```sh
[bundle exec] fastlane test_lane
```

private lane, cannot be used. Just used for developing to testing some action.

### test_upload_to_ykipa_server

```sh
[bundle exec] fastlane test_upload_to_ykipa_server
```


    打iOS测试包,并上传Fir,发送结果给企业微信群
    参数:
      ipa:  [必需] ipa问价绝对路径
      ykipa_save: [可选] 是否上传ykipa存储平台, 默认 0
    command example: ykfastlane test_upload_to_ykipa_server ipa:"/Users/chris/iosYeahArchive/GoodBusinessQ/GoodBusinessQ_3.3.6_1_enterprise_20231019_1416/output/GoodBusinessQ.ipa"


### update_archive_env

```sh
[bundle exec] fastlane update_archive_env
```


    配置 企业微信机器人， fir平台token, pgyer平台token
    参数:
      fir_api_token: [可选] fir平台token
      pgyer_api: [可选] 蒲公英平台api_key
      pgyer_user[可选] 蒲公英平台 user_key
      wxwork_access_token: [可选] 企业微信机器人 webhook中的key字段
      tf_user_name: [必需] apple id
      tf_pass_word: [必需] apple id 专属密钥， 若需配置，请访问：https://appleid.apple.com/account/manage
    command example: ykfastlane update_archive_env fir_api_token:"xxx" pgyer_api:"123456" pgyer_user:"123456" wxwork_access_token:"wxworktoken"


### wx_message_notice

```sh
[bundle exec] fastlane wx_message_notice
```


  通过企业微信机器人，发送消息
      参数：
        wx_notice_token：[可选] 企业微信机器人 webhook中的key字段
        msg_title: [可选] 微信消息标题
        notice_message: [可选] 微信消息内容


### sync_apple_profile

```sh
[bundle exec] fastlane sync_apple_profile
```


  同步苹果开发者后台数据
      参数：
        user_name：apple account
        password: apple account password
        bundle_ids： bundle identifier array, used "," to separate each.
        workspace: workspace path


### update_profiles

```sh
[bundle exec] fastlane update_profiles
```


    更新多个profile
    参数:
    profile_path: profile文件绝对路径，如果有多个，使用 , 隔开


### list_profile_configs

```sh
[bundle exec] fastlane list_profile_configs
```


    显示 profile 配置
    参数: 无参数


### update_certificate_p12

```sh
[bundle exec] fastlane update_certificate_p12
```


    安装p12
    参数:
    password: p12 密码
    cer_path: p12 文件绝对路径


### sync_certificate_profile

```sh
[bundle exec] fastlane sync_certificate_profile
```


    同步git仓库中的 certificate & profile, 如果未传入
，则执行git pull； 否则,覆盖原有的profile & certificate
    参数:
    profile_remote_url: profile & certificate


### list_profile_certificate_config

```sh
[bundle exec] fastlane list_profile_certificate_config
```


    显示 profile & certificate 配置和文件信息


----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
