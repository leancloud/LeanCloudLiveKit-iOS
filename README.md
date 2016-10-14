# LiveKit-iOS


<p align="center">
![enter image description here](https://img.shields.io/badge/platform-iOS%208.0%2B-ff69b5618733984.svg) 
<a href="https://github.com/leancloud/ChatKit-OC/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>
</a>

## 简介

 [LiveKit](https://github.com/leancloud/LeanCloudLiveKit-iOS) 是一个专门为视频直播业务提供的一个 UI 组件。主要特点是：
 
   1. 将直播模块与 IM 模块结合，提供了推流端和播放端，以及聊天室等的实现。
   2. 支持无人数限制的聊天室 
   3. 支持多种自定义消息拓展并提供了默认实现，比如：弹幕、点赞出心、送飞机游轮或保时捷等礼物、成员加入聊天室自动打招呼等。   
   

## 获取项目

 ```Objective-C
git clone --depth=1 https://github.com/leancloud/LeanCloudLiveKit-iOS.git
 ```

## 集成效果

![](http://ww2.sinaimg.cn/large/72f96cbajw1f7q9sn89lzg20nl0l9b2a.gif)

![](http://ww2.sinaimg.cn/large/72f96cbajw1f7q9sdezf9g20nl0l9kjn.gif)

![](http://ww1.sinaimg.cn/large/72f96cbajw1f7q8zdrdpgg20nl0km7wk.gif)

## 项目结构

 ```Objective-C
└── LiveKit-iOS
    ├── LiveKit-iOS
    │   ├── Assets.xcassets
    │   ├── Class
    │   │   ├── Camera
    │   │   │   ├── Controller
    │   │   │   └── View
    │   │   ├── Category
    │   │   ├── Live
    │   │   │   ├── ChildViewController
    │   │   │   ├── Controller
    │   │   │   ├── Model
    │   │   │   └── View
    │   │   ├── Main
    │   │   │   ├── Controller
    │   │   │   └── Libs
    │   │   │       ├── IJKMediaFramework.framework #缺少的库
    │   │   │       └── ... ...
    │   │   └── Mine
    │   │       ├── Category
    │   │       ├── Controller
    │   │       └── View
    │   ├── LiveChat
    │       ├── Model
    │       ├── Resources
    │       │   ├── Gift
    │       │   └── HeartImage
    │       ├── Streaming
    │       │   └── PLCameraStreamingKit
    │       ├── Tool
    │       │   └── MBProgressHUD
    │       └── View
    └── Pods
    ├── ChatKit
        └── Class
        ├── Model
        ├── Module
        ├── Resources
        ├── Tool
        │   ├── Categories
        │   ├── Service
        │   └── Vendor
        └── View
 ```

## 使用方法

本通过 CocoaPods 管理依赖

> CocoaPods 是目前最流行的 Cocoa 项目库依赖管理工具之一，考虑到便捷与项目的可维护性，我们更推荐您使用 CocoaPods 导入并管理 SDK。

### CocoaPods 导入

 1. CocoaPods 安装

  如果您的机器上已经安装了 CocoaPods，直接进入下一步即可。

  如果您的网络已经翻墙，在终端中运行如下命令直接安装：

  ```shell
     sudo gem install cocoapods
  ```

  如果您的网络不能翻墙，可以通过淘宝的 RubyGems 镜像 进行安装。

  在终端依次运行以下命令：

  ```shell
     gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
     sudo gem install cocoapods
  ```

 2. 查询 CocoaPods 源中的本库

  在终端中运行以下命令：

  ```shell
     pod search LiveKit
  ```
 
   这里注意，这个命令搜索的是本机上的最新版本，并没有联网查询。如果运行以上命令，没有搜到或者搜不到最新版本，您可以运行以下命令，更新一下您本地的 CocoaPods 源列表。

  ```shell
     pod repo update
  ```
 
 3. 使用 CocoaPods 导入

  打开终端，进入到您的工程目录，执行以下命令，会自动生成一个 Podfile 文件。

  ```shell
     pod init
  ```

  然后使用 CocoaPods 进行安装。如果尚未安装 CocoaPods，运行以下命令进行安装：

 ```shell
    gem install cocoapods
 ```

  打开 Podfile，在您项目的 target 下加入以下内容。（在此以 v1.0.0 版本为例）

  在文件 `Podfile` 中加入以下内容：

 ```shell
    pod 'LiveKit', '1.0.0'
 ```

  然后在终端中运行以下命令：

 ```shell
    pod install
 ```

  或者这个命令：

 ```shell
    # 禁止升级 CocoaPods 的 spec 仓库，否则会卡在 Analyzing dependencies，非常慢
    pod update --verbose --no-repo-update
 ```

  如果提示找不到库，则可去掉 `--no-repo-update`。

  完成后，CocoaPods 会在您的工程根目录下生成一个 `.xcworkspace` 文件。您需要通过此文件打开您的工程，而不是之前的 `.xcodeproj`。

  如果不想使用 CocoaPods 进行集成，也可以选择使用源码集成。


然后在需要的地方导入 LiveKit：

  ```Objective-C
//TODO
//...
  ```


**CocoaPods 使用说明**

**指定 SDK 版本** 

CocoaPods 中，有几种设置 SDK 版本的方法。如：

`>= 1.0.0` 会根据您本地的 CocoaPods 源列表，导入不低于 1.0.0 版本的 SDK。
`~> 1.0.0` 会根据您本地的 CocoaPods 源列表，介于 1.0.0~1.2.0 之前版本的 SDK。
我们建议您锁定版本，便于团队开发。如，指定 1.0.0 版本。

 ```shell
pod 'LiveKit', '1.0.0'
 ```

 - 升级本地 CocoaPods 源

  `CocoaPods 有一个中心化的源，默认本地会缓存 CocoaPods 源服务器上的所有 SDK 版本。

 如果搜索的时候没有搜到融云的 SDK 或者搜不到最新的 SDK 版本，可以执行以下命令更新一下本地的缓存。

 ```shell
pod repo update
 ```
 
 - 升级工程的 SDK 版本

 更新您工程目录中 Podfile 指定的 SDK 版本后，在终端中执行以下命令。
 ```shell
pod update
 ```


 - 清除 Cocoapods 本地缓存

 特殊情况下，由于网络或者别的原因，通过 CocoaPods 下载的文件可能会有问题。

 这时候您可以删除 CocoaPods 的缓存(~/Library/Caches/CocoaPods/Pods/Release 目录)，再次导入即可。

 - 查看当前使用的 SDK 版本

 您可以在 Podfile.lock 文件中看到您工程中使用的 SDK 版本。

 关于 CocoaPods 的更多内容，您可以参考 [CocoaPods 文档](https://cocoapods.org/)。




如果提示找不到库，则可去掉 `--no-repo-update`。

Pod安装后，会发现，还是少一个framework：`IJKMediaFramework.framework` ,在文档上文中的项目结构部分有标注。可以到这里下载，编译好的版本 ：https://pan.baidu.com/s/1eSBLDpK

## TODO List

现在这个 Demo 还较为简单，仅仅展示了如何为直播 app 集成 IM 模块，大家在 Demo 中看到的直播，是从网上抓包，抓取的直播地址，然后播放的。真正开发时，推流端还是要自己去做，大家可以采用一些第三方的 SDK，比如七牛 SDK，近期会将七牛的 SDK 直接集成进来，这样就真的什么都不用做了。

LiveKit在实现过程中参考了下面的开元项目：

主要是两个部分：

 1. 直播演示部分，主要参考：[520Linkee](https://github.com/GrayJIAXU/520Linkee)   
 2. IM部分，主要参考：[ChatKit-OC](https://github.com/leancloud/ChatKit-OC) 

