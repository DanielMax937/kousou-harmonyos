import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import CommonConstants from '../../common/constants/CommonConstants';
import RdbUtils from '../../common/rdbUtils/RdbUtils';
import { BitstripeApiService } from '../../common/server/BitstripeApiService';
@Component
export struct Settings {
  @Link accountLabel: string;
  @Link userId: string;
  @Link appToken: string;
  @Link serverHost: string;

  @State versionTapCount: number = 0;
  @State showHiddenSettings: boolean = false;
  @State draftHost: string = '';

  aboutToAppear() {
    this.draftHost = this.serverHost || CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;
  }

  showToast(message: string, backgroundColor: string) {
    try {
      promptAction.showToast({
        message,
        shadow: ShadowStyle.OUTER_DEFAULT_SM,
        alignment: Alignment.Top,
        backgroundColor
      });
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`[Settings] toast skipped, code=${err.code}, message=${err.message}`);
    }
  }

  revealHiddenSettings() {
    this.versionTapCount += 1;
    if (this.versionTapCount >= 6) {
      this.showHiddenSettings = true;
      this.versionTapCount = 0;
      this.showToast('调试设置已开启', '#a6f499');
    }
  }

  saveHost() {
    const host = (this.draftHost || CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST).trim().replace(/\/v1\/kousou\/?$/, '').replace(/\/$/, '');
    this.serverHost = host;
    BitstripeApiService.setServerHost(host);
    const context = getContext(this) as common.UIAbilityContext;
    RdbUtils.saveKousouServerHost(context, host).then(() => {
      this.showToast('服务端地址已保存', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`保存失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  resetHost() {
    this.draftHost = CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;
    this.saveHost();
  }

  goLogin() {
    router.pushUrl({ url: CommonConstants.LOGIN_PAGE_URL });
  }

  goCategoryManage() {
    router.pushUrl({ url: CommonConstants.CATEGORY_MANAGE_PAGE_URL });
  }

  build() {
    Scroll() {
      Column() {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ top: 10, bottom: 12 })

        Row() {
          Text('账号与同步')
            .fontSize(16)
            .fontColor('#111')
          Text(this.userId === 'local' ? '去登录' : this.accountLabel)
            .fontSize(14)
            .fontColor(this.userId === 'local' ? '#2f7468' : '#66736f')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .margin({ left: 16 })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { bottom: 1 }, color: '#edf0ec' })
        .onClick(() => {
          this.goLogin();
        })

        Row() {
          Text('隐私政策')
            .fontSize(16)
            .fontColor('#111')
          Text('查看')
            .fontSize(14)
            .fontColor('#2f7468')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { bottom: 1 }, color: '#edf0ec' })
        .onClick(() => {
          router.pushUrl({ url: CommonConstants.PRIVACY_PAGE_URL });
        })

        Row() {
          Text('服务协议')
            .fontSize(16)
            .fontColor('#111')
          Text('查看')
            .fontSize(14)
            .fontColor('#2f7468')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { bottom: 1 }, color: '#edf0ec' })
        .onClick(() => {
          router.pushUrl({ url: CommonConstants.TERMS_PAGE_URL });
        })

        Row() {
          Text('分类管理')
            .fontSize(16)
            .fontColor('#111')
          Text('管理')
            .fontSize(14)
            .fontColor('#2f7468')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { bottom: 1 }, color: '#edf0ec' })
        .onClick(() => {
          this.goCategoryManage();
        })

        Row() {
          Text('版本号')
            .fontSize(16)
            .fontColor('#111')
          Text(CommonConstants.APP_VERSION_NAME)
            .fontSize(14)
            .fontColor('#66736f')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { top: 1, bottom: 1 }, color: '#edf0ec' })
        .onClick(() => {
          this.revealHiddenSettings();
        })

        if (this.showHiddenSettings) {
          Column() {
            Text('调试设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111')
              .width('100%')
            TextInput({ placeholder: CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST, text: this.draftHost })
              .height(42)
              .fontSize(14)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.draftHost = value;
              })
            Row() {
              Button('保存')
                .height(40)
                .layoutWeight(1)
                .backgroundColor('#a1e0cf')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.saveHost();
                })
              Button('恢复线上')
                .height(40)
                .layoutWeight(1)
                .margin({ left: 8 })
                .backgroundColor('#edf0ec')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.resetHost();
                })
            }
            .width('100%')
            .margin({ top: 10 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 16, bottom: 16, left: 14, right: 14 })
          .margin({ top: 14 })
          .backgroundColor('#f2f5f0')
          .border({ radius: 8 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .scrollBar(BarState.Off)
    .scrollBarColor(Color.Transparent)
    .scrollBarWidth(0)
    .width('100%')
    .height('100%')
  }
}
