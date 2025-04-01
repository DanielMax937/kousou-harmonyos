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

/**
 * The LauncherPage is the entry point of the application and shows how to develop the LauncherPage.
 * Stay on the LauncherPage for a few seconds to jump to the AdvertisingPage.
 * Developers can replace the background image.
 */
@Entry
@Component
struct LauncherPage {
  controller: webview.WebviewController = new webview.WebviewController();

  private context?: common.UIAbilityContext;
  private timerId: number = 0;
  private isJumpToAdvertising: boolean = false;
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
          Web({ src: 'https://www.bitstripe.cn?from=hongmeng', controller: this.controller })
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