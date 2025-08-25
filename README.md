## 总结
1. navigation是用来展示子页面的。所以如果tab的形式，还是需要独立页面的形式
2. 自定义组件，可以类比有状态的container，@Builder函数类比无状态的UI组件
3. 如果涉及到slot，需要BuilderParam
4. 子组件的state可以理解为props通过调用方传入
5. height无明确，是默认其子元素的高度，如果写了100%，会找到祖先的有明确高度的父节点，默认为屏幕剩余未占位的高度
6. 尽量用class，不要用object
7. preview不支持数据库，会报错。用模拟器
8. foreach循环，如果是对象数组，需要加index
9. 类型声明时，如果是动态key，需要使用Record
10. 如果修改代码不生效，需要build-rebuild或者file-invalidate caches

11. p12 生成csr，csr生成cer 这两个是应用无关的，只用来生成证书。生成csr过程中需要设置store password和alias以及对应password，这两个也是和应用无关的。但是在后面设置sign时，必须和生成csr的对上
12. p7b生成时，需要选择证书和应用，证书是上面用的。然后通过选应用绑定在一起

### 资源文件
1. build-profile.json5中存放签名配置，其中product决定用哪个配置，不同设备配置不一样
2. AppScope中，app.json5决定展示在桌面的图标和文案
3. main/resources/base/profile/main_pages.json，决定使用的页面，新增页面要改这里
4. main/module.json5,决定启动界面和入口页面地址
   1. AppScope > resources ：用于存放应用需要用到的资源文件（应用图标）。
   2. Module_name （Entry）> src > main > resources ：用于存放该Module需要用到的资源文件（应用运行的资源，一些jpg，svg，png图片等）

### webview调试
1. 需要hdc shell进入到连着的真机
2. 需要通过 cat /proc/net/unix | grep devtools 找到对应的pid
3. 需要在本地 hdc fport tcp:9222 localabstract:webview_devtools_remote_xxx 执行转发
4. 然后在chrome中，选中network类型，配置localhost:9222，然后就能看到目标进行调试了
5. 在上述之前，代码里要做相关改动
```js
aboutToAppear(){
    // 开启调试
    webview.WebviewController.setWebDebuggingAccess(true)
  }
```

### webview
1. 如果需要支持localstorage，需要在使用domStorageAccess设置为true
```
Web({ src: 'http://192.168.41.48:3001?from=hongmeng', controller: this.controller }).domStorageAccess(true)
```
2. 使用postmessage和原生进行通信，不过报错，说 port can post message
3. 使用jsBridge，这个可以具体看官方文档,走的通
4. cookie持久化，可以通过preference来做，先通过jsbridge获取登录状态，然后获取cookie，然后存储，然后在打开时进行同步

### 一键授权
1. https://juejin.cn/post/7453304066451275795 （整体流程）
2. OPEN_ID：华为账号用户的OpenID;UNION_ID：华为账号用户的UnionID。 在需要唯一标识用户身份的场景下，通常使用UNION_ID，因为它在同一开发者账号下的不同应用中是一致的。
3. 配置指纹后，按官方文档说是需要25小时后生效（好像是在本地打包会缓存这么久，所以有些人通过设置系统时间回拨一天来避免此问题）


### 后台和上架管理
1. 打包时，用模拟器，会采用和上架中心一样的证书，所以ok。但是如果是用手机的证书，由于是自动生成，和应用中心不一致，导致profile失败
2. 网站的备案不能用于app的，app备案需要包的信息，可以使用这里的方式 https://cloud.tencent.com/developer/article/2481065


## 参考资源
1. [启动弹窗](https://blog.csdn.net/2301_79900717/article/details/140708027)
    1. 如何设置全局对象，如何设置和读取preference,如何设置自定义弹窗，如果页面跳转
2. [基础概念](https://blog.csdn.net/m0_68038853/article/details/139246403)
3. [资源分类和访问](https://blog.csdn.net/a6051529/article/details/137387476)
4. [图标设置](https://developer.huawei.com/consumer/cn/forum/topic/0201165322333298054)
5. [学习资料](https://www.cnblogs.com/shudaoshan/p/18224414)
6. [webview调试](https://blog.csdn.net/Mayism123/article/details/139534057)
7. [webview和原生通信](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-in-page-app-function-invoking)