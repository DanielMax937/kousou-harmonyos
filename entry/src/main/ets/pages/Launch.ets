import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import Logger from '../common/utils/Logger';
import CommonConstants from '../common/constants/CommonConstants';
import CustomDialogComponent from '../view/CustomDialogComponent';
import { GlobalContext } from '../common/utils/GlobalContext';

@Entry
@Component
struct LauncherPage {
  private context?: common.UIAbilityContext;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogComponent({
      cancel: () => {
        this.onCancel();
      },
      confirm: () => {
        this.onConfirm();
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: CommonConstants.DIALOG_CONTROLLER_DY_OFFSET },
    customStyle: true,
    autoCancel: false
  });

  onCancel() {
    this.context?.terminateSelf();
  }

  onConfirm() {
    this.saveIsPrivacy(() => {
      this.goToHome();
    });
  }

  onPageShow() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.getDataPreferences(this).then((preferences: preferences.Preferences) => {
      preferences.get(CommonConstants.PREFERENCES_KEY_PRIVACY, true).then((value: preferences.ValueType) => {
        Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'onPageShow value: ' + value);
        if (value) {
          const isJumpPrivacy: boolean = (GlobalContext.getContext().getObject('isJumpPrivacy') as boolean) ?? false;
          if (!isJumpPrivacy) {
            this.dialogController.open();
          }
        } else {
          this.goToHome();
        }
      });
    });
  }

  saveIsPrivacy(onSaved?: () => void) {
    const preferences: Promise<preferences.Preferences> = this.getDataPreferences(this);
    preferences.then((result: preferences.Preferences) => {
      const privacyPut = result.put(CommonConstants.PREFERENCES_KEY_PRIVACY, false);
      privacyPut.then(() => {
        result.flush().then(() => {
          Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Put the value of startup Successfully.');
          if (onSaved) {
            onSaved();
          }
        }).catch((err: Error) => {
          Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Flush the value of startup Failed, err: ' + err);
        });
      }).catch((err: Error) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Put the value of startup Failed, err: ' + err);
      });
    }).catch((err: Error) => {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get the preferences Failed, err: ' + err);
    });
  }

  goToHome() {
    router.replaceUrl({
      url: 'pages/Index'
    }).catch((error: Error) => {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'LauncherPage replaceUrl error ' + JSON.stringify(error));
    });
  }

  getDataPreferences(common: Object) {
    return preferences.getPreferences(getContext(common), CommonConstants.PREFERENCES_FILE_NAME);
  }

  build() {
    Column() {
      Image($r('app.media.layered_image'))
        .width(92)
        .height(92)
        .margin({ bottom: 18 })
      Text('抠搜记账')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111')
      Text('本地记账与端侧识别')
        .fontSize(14)
        .fontColor('#7d8985')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#f9faf5')
  }
}
