# LeanCloudLiveKit-iOS

演示如何为直播项目添加IM系统，集成 IM 后的效果图如下：

![](http://ww2.sinaimg.cn/large/72f96cbajw1f7q9sn89lzg20nl0l9b2a.gif)

![](http://ww2.sinaimg.cn/large/72f96cbajw1f7q9sdezf9g20nl0l9kjn.gif)

![](http://ww1.sinaimg.cn/large/72f96cbajw1f7q8zdrdpgg20nl0km7wk.gif)


本Demo，主要是两个部分：

 1. 直播演示部分，主要参考： [520Linkee](https://github.com/GrayJIAXU/520Linkee)   
 2. IM部分，主要参考：[ChatKit-OC](https://github.com/leancloud/ChatKit-OC) 


Pod安装后，会发现，还是少一个framework： `IJKMediaFramework.framework` , 可以到这里下载，编译好的版本 ：https://pan.baidu.com/s/1eSBLDpK

详情请参考： [520Linkee](https://github.com/GrayJIAXU/520Linkee)   。


## TODO List

现在这个 Demo 还较为简单，仅仅展示了如何为直播 app 集成 IM 模块，大家在 Demo 中看到的直播，是从网上抓包，抓取的直播地址，然后播放的。真正开发时，推流端还是要自己去做，大家可以采用一些第三方的 SDK，比如七牛 SDK，近期会将七牛的 SDK 直接集成进来，这样就真的什么都不用做了。