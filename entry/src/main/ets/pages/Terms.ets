// Second.ets
import { BusinessError } from '@kit.BasicServicesKit';
import { webview } from '@kit.ArkWeb';


@Entry
@Component
struct Terms {
  @State message: string = 'Hi there'
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Row() {
      Column() {
        Web({ src: 'https://www.bitstripe.cn/terms?from=hongmeng', controller: this.controller })
      }
      .width('100%')
    }
    .height('100%')
  }
}