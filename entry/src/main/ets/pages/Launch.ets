/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import Logger from '../common/utils/Logger';
import CommonConstants from '../common/constants/CommonConstants';
import CustomDialogComponent from '../view/CustomDialogComponent';
import { GlobalContext } from '../common/utils/GlobalContext';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

class  BitJsBridgeClass {
  private preferences: Promise<preferences.Preferences>;
  constructor(preferences: Promise<preferences.Preferences>) {
    this.preferences = preferences
  }

  login(url: string): string {
    const cookie = webview.WebCookieManager.fetchCookieSync(url)
    this.preferences.then((result: preferences.Preferences) => {
      let privacyPut = result.put(CommonConstants.PREFERENCES_KEY_COOKIE, cookie);
      result.flush();
      privacyPut.then(() => {
        Logger.info(CommonConstants.PREFERENCES_KEY_COOKIE, 'Put the value of cookie Successfully.');
      }).catch((err: Error) => {
        Logger.error(CommonConstants.PREFERENCES_KEY_COOKIE, 'Put the value of cookie Failed, err: ' + err);
      });
    }).catch((err: Error) => {
      Logger.error(CommonConstants.PREFERENCES_KEY_COOKIE, 'Get the preferences Failed, err: ' + err);
    });
    return 'save cookie success';
  }
}

/**
 * The LauncherPage is the entry point of the application and shows how to develop the LauncherPage.
 * Stay on the LauncherPage for a few seconds to jump to the AdvertisingPage.
 * Developers can replace the background image.
 *
 */
@Entry
@Component
struct LauncherPage {

  controller: webview.WebviewController = new webview.WebviewController();
  ports: webview.WebMessagePort[] = [];
  selfPreference = this.getDataPreferences(this)
  @State jsBridge:  BitJsBridgeClass = new  BitJsBridgeClass(this.selfPreference);
  private host: string = "https://www.bitstripe.cn"
  private context?: common.UIAbilityContext;
  private timerId: number = 0;
  private isJumpToAdvertising: boolean = false;
  private webviewCookie: string = '';
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogComponent(
      {
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
    // Exit the application.
    this.context?.terminateSelf();
  }

  onConfirm() {
    // Save privacy agreement status.
    this.saveIsPrivacy();
    // this.jumpToAdvertisingPage();
  }

  onPageHide() {
    // if (this.isJumpToAdvertising) {
    //   router.clear();
    // }
    // globalThis.isJumpPrivacy = true;
    // GlobalContext.getContext().setObject('isJumpPrivacy', true);
    // clearTimeout(this.timerId);
  }

  /**
   * Jump to advertising page.
   */
  jumpToAdvertisingPage() {
    this.timerId = setTimeout(() => {
      this.isJumpToAdvertising = true;
      router.pushUrl({
        url: CommonConstants.ADVERTISING_PAGE_URL
      }).catch((error: Error) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'LauncherPage pushUrl error ' + JSON.stringify(error));
      });
    }, CommonConstants.LAUNCHER_DELAY_TIME);
  }

  saveIsPrivacy() {
    let preferences: Promise<preferences.Preferences> = this.getDataPreferences(this);
    preferences.then((result: preferences.Preferences) => {
      let privacyPut = result.put(CommonConstants.PREFERENCES_KEY_PRIVACY, false);
      result.flush();
      privacyPut.then(() => {
        Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Put the value of startup Successfully.');
      }).catch((err: Error) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Put the value of startup Failed, err: ' + err);
      });
    }).catch((err: Error) => {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get the preferences Failed, err: ' + err);
    });
  }
  aboutToAppear(){
    webview.WebviewController.setWebDebuggingAccess(true)
    this.getDataPreferences(this).then((preferences: preferences.Preferences) => {
      preferences.get(CommonConstants.PREFERENCES_KEY_COOKIE, true).then((value: preferences.ValueType) => {
        Logger.info(CommonConstants.PREFERENCES_KEY_COOKIE, 'onPageShow value: ' + value);
        if (value) {
          const cookieList = (value as string).split(";")
          for (let index = 0; index < cookieList.length; index++) {
            const element = cookieList[index];
            webview.WebCookieManager.configCookieSync(this.host, element)
          }
        } else {
          Logger.info(CommonConstants.PREFERENCES_KEY_COOKIE, 'onPageShow no cookie find');
        }
      });
    });

  }

  onPageShow() {
    this.context = getContext(this) as common.UIAbilityContext;
    // Get the operation class for saving data.
    this.getDataPreferences(this).then((preferences: preferences.Preferences) => {
      preferences.get(CommonConstants.PREFERENCES_KEY_PRIVACY, true).then((value: preferences.ValueType) => {
        Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'onPageShow value: ' + value);
        if (value) {
          // let isJumpPrivacy: boolean = globalThis.isJumpPrivacy ?? false;
          let isJumpPrivacy: boolean = (GlobalContext.getContext().getObject('isJumpPrivacy') as boolean) ?? false;
          if (!isJumpPrivacy) {
            this.dialogController.open();
          }
        } else {
          // this.jumpToAdvertisingPage();
        }
      });
    });
  }

  /**
   * Get data preferences action.
   */
  getDataPreferences(common: Object) {
    return preferences.getPreferences(getContext(common), CommonConstants.PREFERENCES_FILE_NAME);
  }

  build() {
    Stack() {
      Row() {

        Column() {
          Web({ src: this.host + '?from=hongmeng', controller: this.controller })
            .javaScriptAccess(true)
            .fileAccess(true)
            .geolocationAccess(true)
            .domStorageAccess(true)
            .onlineImageAccess(true)
            .javaScriptProxy({
              object: this.jsBridge,
              name: "bitJsBridge",
              methodList: ["login"],
              controller: this.controller
            })
            .onPageEnd(() => {
              try {
                // 1、创建两个消息端口。
                this.ports = this.controller.createWebMessagePorts();

                // 2、在应用侧的消息端口(如端口1)上注册回调事件。
                this.ports[1].onMessageEvent((result: webview.WebMessage) => {
                  let msg = 'Got msg from HTML:';
                  if (typeof (result) === 'string') {
                    Logger.info(`received string message from html5, string is: ${result}`);
                    msg = msg + result;
                  } else if (typeof (result) === 'object') {
                    if (result instanceof ArrayBuffer) {
                      Logger.info(`received arraybuffer from html5, length is: ${result.byteLength}`);
                      msg = msg + 'length is ' + result.byteLength;
                    } else {
                      Logger.info('not support');
                    }
                  } else {
                    Logger.info('not support');
                  }
                })
                // 设置在onPageEnd, 确保页面已加载完成
                this.controller.postMessage('__init_port__', [this.ports[0]], '*');
              } catch (error) {
                Logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
          })
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
// Healthy living text common styles.
@Extend(Text) function healthyLifeTextStyle (fontWeight: number,
  textAttribute: number, fontSize: Resource, fontColor: Resource) {
  .fontWeight(fontWeight)
  .letterSpacing(textAttribute)
  .fontSize(fontSize)
  .fontColor(fontColor)
}