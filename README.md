# ykfastlane

基于 fasltlane 的通用打包脚本。借助 gem 包 ykcitool 执行。是 iOS 打包的核心。

## 部署

iOS 打包借助 Jenkins 作为 UI 端，由 master-slave 形式部署。

- master 作为门户，主要复制任务的触发，已由运维开通 vpn,支持通过 VPN 居家访问。
- slave 作为打包任务的主题，负责实际执行打包任务，可以部署多个 slave。
- slave 通过部署 ykcitool， ykfastlane, 具体负责打包任务的执行，证书管理。
- iOS 的证书，通过 gitlab 仓库统一管理， 各个 slave 可以通过 ykcitool 同步证书。
