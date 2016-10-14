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
    │   ├── LiveChat                               #推流端和播放端
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
    ├── ChatKit                                    #IM系统
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

本库通过 CocoaPods 管理依赖。

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

 2. 使用 CocoaPods 导入

   打开终端，然后使用 CocoaPods 进行安装。如果尚未安装 CocoaPods，运行以下命令进行安装：

 ```shell
    gem install cocoapods
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


Pod安装后，会发现，还是少一个framework：`IJKMediaFramework.framework` ,在文档上文中的项目结构部分有标注。可以到这里下载，编译好的版本 ：https://pan.baidu.com/s/1eSBLDpK

## 推流端与播放端

### 推流端配置

Demo 中使用了七牛 SDK 的推流端，具体配置方法需要参考：
 
  1. [《七牛开发者中心-API文档》]( http://developer.qiniu.com/article/index.html#pili-api-handbook ) 
  2. [《2小时搞定移动直播 App 开发》](http://www.imooc.com/learn/707?sukey=f740b693ad416b27703fbe1bfb6cc97b973f0a33f4b940c57d8ba98cf76ac97363149884f0b55604da9f6135c6942f40) 视频教程
  
播放端是采用的通用的直播组件，Demo 中实时播放的直播地址，是从网上抓包抓取的直播地址。如果想观看推流端的直播视频，直接替换 URL 地址就可以达到效果。

播放端和推流端的代码位置，在上文的项目项目结构部分已经标注出。

## IM 系统配置

IM 部分的配置需要参考：[ChatKit-OC](https://github.com/leancloud/ChatKit-OC) 。

IM 系统的的代码位置，在上文的项目项目结构部分已经标注出。

**参考到的开源项目**

主要是两个部分：

 1. 直播演示部分，主要参考：[520Linkee](https://github.com/GrayJIAXU/520Linkee)   
 2. IM部分，主要参考：[ChatKit-OC](https://github.com/leancloud/ChatKit-OC) 

