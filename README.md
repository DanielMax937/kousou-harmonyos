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


### 后台和上架管理
1. TODO


## 参考资源
1. [启动弹窗](https://blog.csdn.net/2301_79900717/article/details/140708027)
    1. 如何设置全局对象，如何设置和读取preference,如何设置自定义弹窗，如果页面跳转
2. [基础概念](https://blog.csdn.net/m0_68038853/article/details/139246403)
3. [资源分类和访问](https://blog.csdn.net/a6051529/article/details/137387476)
4. [图标设置](https://developer.huawei.com/consumer/cn/forum/topic/0201165322333298054)
