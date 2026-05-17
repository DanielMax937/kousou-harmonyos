@Entry
@Component
struct Privacy {
  build() {
    Scroll() {
      Column() {
        Text('隐私政策')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .width('100%')
          .margin({ bottom: 18 })
        Text('抠搜记账会在本机保存你主动录入的记账记录、金额、分类、备注和登录状态。未登录时，数据优先保存在本地。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('当你使用华为账号登录后，应用会使用账号标识关联你的记账数据，并通过 bitstripe 服务端完成数据保存和多设备恢复。相关数据仅用于恢复和跨设备使用记账记录。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('当你选择发票或小票图片识别时，应用会将该图片提交给服务端 LLM 识别接口，用于提取文字、消费金额和分类建议。该图片仅用于本次识别处理。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor('#333')
          .margin({ bottom: 14 })
        Text('你可以通过系统设置管理应用权限，也可以卸载应用清除本地数据。')
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
