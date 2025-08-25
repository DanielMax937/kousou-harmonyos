import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import RdbUtils from '../common/rdbUtils/RdbUtils';


export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Login', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });

    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: "RdbTest.db",
      securityLevel: relationalStore.SecurityLevel.S1
    };

    relationalStore.getRdbStore(this.context, STORE_CONFIG, (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
      if (err) {
        console.error(`[RdbInfo]Get RdbStore failed, code is ${err.code},message is ${err.message}`);
        return;
      }
      console.log('[RdbInfo] get success')
      RdbUtils.setStore(rdbStore);
      RdbUtils.executeSql('CREATE TABLE IF NOT EXISTS ACCOUNT (ID INTEGER PRIMARY KEY AUTOINCREMENT, TAG TEXT NOT NULL, TYPE TEXT NOT NULL, AMOUNT TEXT NOT NULL, CREATE_AT DATETIME DEFAULT CURRENT_TIMESTAMP)').then((res) => {
        console.log('[RdbInfo] create success')
      }).catch((err: BusinessError)=> {
        console.log('[RdbInfo] create failed')
      })
    })

    // const context = AppStorage.get<Context>('Context')
    // let preference = dataPreferences.getPreferencesSync(context,{
    //   name:'STORAGE'
    // })
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}