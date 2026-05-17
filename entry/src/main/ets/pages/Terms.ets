@Entry
@Component
struct Terms {
  build() {
    Scroll() {
      Column() {
        Text('服务协议')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .width('100%')
          .margin({ bottom: 18 })
        Text('欢迎使用抠搜记账。本应用用于本地记录收入、支出、消费备注和相关分类，并可在登录华为账号后保存到 bitstripe 服务端。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('你应确保录入内容真实、合法，并自行管理账号、设备和数据备份。应用提供的端侧文字识别仅用于辅助填入金额和分类，识别结果可能存在误差，保存前请自行核对。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('除法律法规另有规定外，因网络、设备、系统权限、第三方服务或用户误操作导致的数据保存失败、数据不完整或识别错误，本应用将在合理范围内协助处理，但不承诺完全避免。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('继续使用本应用即表示你理解并同意以上条款。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
      }
      .padding({ left: 22, right: 22, top: 28, bottom: 32 })
      .width('100%')
    }
    .backgroundColor('#f9faf5')
    .height('100%')
  }
}
