import { Home } from './components/Home'
import { INIT_TAG, Money, Tag } from './components/Money';
import { MyKeyboard } from './components/MyKeyboard';
import { Settings } from './components/Settings';
import { Statistics } from './components/Statistics';
import { Wishlist } from './components/Wishlist';
import { promptAction } from '@kit.ArkUI';
import RdbUtils from '../common/rdbUtils/RdbUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HuaweiAccountService, HuaweiAccountSession } from '../common/account/HuaweiAccountService';
import { OnDeviceAccountingAiService } from '../common/ai/OnDeviceAccountingAiService';
import { ReceiptOcrService } from '../common/ai/ReceiptOcrService';
import { BitstripeApiService, ReceiptRecognitionItem, ServerAccountRecord } from '../common/server/BitstripeApiService';
import CommonConstants from '../common/constants/CommonConstants';

@Entry
@Component
struct Index {
  @State currentMenu: string = 'home';
  @State selectedTag: Tag | null = null;
  @State accountLabel: string = '未登录';
  @State userId: string = 'local';
  @State appToken: string = '';
  @State smartText: string = '';
  @State noteText: string = '';
  @State parsedAmount: string = '';
  @State ocrLoading: boolean = false;
  @State receiptItems: ReceiptRecognitionItem[] = [];
  @State syncRevision: number = 0;
  @State serverHost: string = CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;

  getMenuTitle(name: string) {
    if (name === 'home') {
      return '今天';
    }
    if (name === 'money') {
      return '记账';
    }
    if (name === 'statistics') {
      return '统计';
    }
    if (name === 'wishlist') {
      return '心愿';
    }
    if (name === 'settings') {
      return '设置';
    }
    return '统计';
  }

  getMenuIcon(name: string) {
    if (name === 'statistics') {
      return 'chart.svg';
    }
    if (name === 'wishlist') {
      return 'tag.svg';
    }
    if (name === 'settings') {
      return 'overview.svg';
    }
    return `${name}.svg`;
  }

  @Builder homeBuilder() {
    Column() {
      Row() {
        Text('Today')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .height(58)
          .align(Alignment.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#010101')
      }
      Row() {
        Column() {
          Text(this.accountLabel)
            .fontSize(14)
            .fontColor('#333')
            .fontWeight(FontWeight.Medium)
          Text(this.userId === 'local' ? '本地数据，登录后可保存到服务端' : '服务端账号数据')
            .fontSize(12)
            .fontColor('#8d9996')
            .margin({ top: 2 })
        }
        Button(this.userId === 'local' ? '华为账号登录' : '刷新登录')
          .fontSize(13)
          .height(34)
          .backgroundColor('#a1e0cf')
          .fontColor('#1f2f2b')
          .onClick(() => {
            this.loginWithHuawei();
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })

      Column() {
        TextInput({ placeholder: '例如：午餐 35、工资 8000', text: this.smartText })
          .height(42)
          .fontSize(14)
          .backgroundColor('#f2f5f0')
          .border({ radius: 8 })
          .onChange((value: string) => {
            this.smartText = value;
          })
        Row() {
          Button(this.ocrLoading ? '识别中...' : '识别图片')
            .fontSize(13)
            .height(34)
            .backgroundColor('#f1c21a')
            .fontColor('#222')
            .onClick(() => {
              this.recognizeReceiptImage();
            })
          Button('解析文本')
            .fontSize(13)
            .height(34)
            .margin({ left: 8 })
            .backgroundColor('#dce7e2')
            .fontColor('#1f2f2b')
            .onClick(() => {
              this.applyOnDeviceAi();
            })
          if (this.selectedTag && this.parsedAmount) {
            Text(`${this.selectedTag.name} ¥${this.parsedAmount}`)
              .fontSize(13)
              .fontColor('#65706d')
              .margin({ left: 10 })
          }
        }
        .margin({ top: 8 })
        if (this.receiptItems.length > 0) {
          Column() {
            ForEach(this.receiptItems, (item: ReceiptRecognitionItem, index: number) => {
              Row() {
                Text(`${item.category || '日用品'} · ${item.description || '票据项目'}`)
                  .fontSize(12)
                  .fontColor('#34413d')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`¥${item.amount}`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111')
              }
              .width('100%')
              .padding({ top: 5, bottom: 5 })
            }, (item: ReceiptRecognitionItem, index: number) => `${index}_${item.description}_${item.amount}`)
            Button('全部入账')
              .fontSize(13)
              .height(34)
              .width('100%')
              .margin({ top: 6 })
              .backgroundColor('#a1e0cf')
              .fontColor('#1f2f2b')
              .onClick(() => {
                this.saveReceiptItems();
              })
          }
          .width('100%')
          .margin({ top: 8 })
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor('#fff')
          .border({ radius: 8, width: 1, color: '#edf0ec' })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 12 })

      Home({ currentMenu: $currentMenu, userId: $userId, syncRevision: $syncRevision})
        .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder countBuilder() {
    Column(){
      Money({
        selectedTag: $selectedTag,
        userId: $userId,
        appToken: $appToken
      })
        .layoutWeight(1)

      TextInput({ placeholder: '备注，例如：和朋友午餐、客户报销', text: this.noteText })
        .height(42)
        .fontSize(14)
        .backgroundColor('#f2f5f0')
        .border({ radius: 8 })
        .margin({ left: 18, right: 18, top: 4, bottom: 4 })
        .onChange((value: string) => {
          this.noteText = value;
        })

      MyKeyboard({
        selectedTag: $selectedTag,
        parsedAmount: $parsedAmount,
        smartText: $smartText,
        noteText: $noteText,
        userId: $userId,
        appToken: $appToken,
        currentMenu: $currentMenu
      })
        .height(268)
    }

  }

  @Builder statisticsBuilder() {
    Statistics({ userId: $userId, appToken: $appToken, syncRevision: $syncRevision })
  }

  @Builder wishlistBuilder() {
    Wishlist({ userId: $userId, appToken: $appToken })
  }

  @Builder settingsBuilder() {
    Settings({
      accountLabel: $accountLabel,
      userId: $userId,
      appToken: $appToken,
      serverHost: $serverHost
    })
  }

  aboutToAppear() {
    this.restoreSavedAuth();
  }

  onPageShow() {
    if (this.userId !== 'local' && this.appToken) {
      this.syncWithServer();
    }
  }

  async restoreSavedAuth() {
    const context = getContext(this) as common.UIAbilityContext;
    this.serverHost = await RdbUtils.loadKousouServerHost(context, CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST);
    BitstripeApiService.setServerHost(this.serverHost);
    const savedAuth = await RdbUtils.loadKousouAuth(context);
    if (savedAuth) {
      this.userId = savedAuth.userId;
      this.appToken = savedAuth.token;
      this.accountLabel = savedAuth.accountLabel;
      this.syncWithServer();
      return;
    }
    this.trySilentLogin();
  }

  async trySilentLogin() {
    const context = getContext(this) as common.UIAbilityContext;
    const session = await HuaweiAccountService.silentLogin(context);
    if (session) {
      this.applySession(session);
    }
  }

  async loginWithHuawei() {
    const context = getContext(this) as common.UIAbilityContext;
    try {
      const session = await HuaweiAccountService.login(context);
      this.applySession(session);
      promptAction.showToast({message: '华为账号登录成功', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#a6f499'})
    } catch (error) {
      promptAction.showToast({message: '华为账号登录失败', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
    }
  }

  applySession(session: HuaweiAccountSession) {
    if (!session.authorizationCode) {
      promptAction.showToast({message: '需要重新登录以获取服务端令牌', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
      return;
    }
    BitstripeApiService.authHuawei(session).then((authResult) => {
      this.userId = authResult.userId;
      this.appToken = authResult.token;
      this.accountLabel = `已登录 ${authResult.userId}`;
      hilog.info(0x0000, 'ServerSync', 'applySession user=%{public}s', authResult.userId);
      const context = getContext(this) as common.UIAbilityContext;
      RdbUtils.getKousouLastSyncAt(context).then((lastSyncAt: string) => {
        return RdbUtils.saveKousouAuth(context, {
          userId: this.userId,
          token: this.appToken,
          expiresAt: authResult.expiresAt,
          accountLabel: this.accountLabel,
          lastSyncAt
        });
      }).catch((error: BusinessError) => {
        console.warn(`[ServerSync] save auth failed, code=${error.code}, message=${error.message}`);
      });
      RdbUtils.migrateLocalRecordsToUser(this.userId).then(() => {
        this.syncWithServer();
      });
    }).catch((error: BusinessError) => {
      console.error(`[ServerSync] auth failed, code=${error.code}, message=${error.message}`);
      promptAction.showToast({message: '服务端登录失败', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
    });
  }

  syncWithServer() {
    if (!this.appToken || this.userId === 'local') {
      return;
    }
    const context = getContext(this) as common.UIAbilityContext;
    RdbUtils.queryPendingRecords(this.userId).then((records) => {
      const tasks = records.map((record) => {
        return BitstripeApiService.createRecord(this.appToken, record).then(() => {
          return RdbUtils.markRecordSynced(record.RECORD_ID ?? '');
        });
      });
      return Promise.all(tasks);
    }).then(() => {
      return RdbUtils.getKousouLastSyncAt(context);
    }).then((lastSyncAt: string) => {
      return BitstripeApiService.syncRecords(this.appToken, lastSyncAt);
    }).then((records: ServerAccountRecord[]) => {
      const tasks = records.map((record) => {
        return RdbUtils.upsertServerRecord({
          RECORD_ID: record.recordId,
          TAG: record.tag,
          TAG_ID: record.tagId ?? 0,
          IS_USER_TAG: record.isUserTag ? 1 : 0,
          TYPE: record.type,
          AMOUNT: record.amount,
          USER_ID: this.userId,
          NOTE: record.note,
          SYNC_STATUS: 'SYNCED',
          CREATE_AT: record.occurredAt,
          UPDATED_AT: record.updatedAt,
          DEVICE_ID: record.deviceId,
          VERSION: record.version,
          IS_DELETED: record.isDeleted ? 1 : 0
        });
      });
      return Promise.all(tasks).then(() => {
        const serverUpdatedAtList = records
          .map((record: ServerAccountRecord) => record.serverUpdatedAt ?? '')
          .filter((value: string) => value.length > 0)
          .sort();
        const lastSyncAt = serverUpdatedAtList.length > 0 ? serverUpdatedAtList[serverUpdatedAtList.length - 1] : '';
        if (lastSyncAt) {
          return RdbUtils.saveKousouLastSyncAt(context, lastSyncAt);
        }
        return Promise.resolve();
      });
    }).then(() => {
      this.syncRevision += 1;
    }).catch((error: BusinessError) => {
      console.error(`[ServerSync] sync failed, code=${error.code}, message=${error.message}`);
    });
  }

  async recognizeReceiptImage() {
    if (this.ocrLoading) {
      return;
    }
    this.ocrLoading = true;
    try {
      if (!this.appToken) {
        promptAction.showToast({message: '请先登录华为账号', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
        return;
      }
      const result = await ReceiptOcrService.recognizeFromPicker(this.appToken);
      if (!result) {
        return;
      }
      this.smartText = result.text;
      this.receiptItems = result.items.map((item: ReceiptRecognitionItem) => {
        const normalized: ReceiptRecognitionItem = {
          description: item.description ?? result.text,
          amount: `${item.amount}`,
          type: item.type === 'income' ? 'income' : 'expense',
          category: item.category || result.tag || '日用品',
          date: item.date,
          selected: true
        };
        return normalized;
      });
      if (result.amount) {
        this.parsedAmount = result.amount;
      }
      if (result.tag) {
        const tag = INIT_TAG.find((item) => item.name === result.tag);
        if (tag) {
          this.selectedTag = tag;
        }
      }
      if (this.receiptItems.length === 0) {
        this.applyOnDeviceAi();
      }
    } catch (error) {
      const err = error as BusinessError;
      promptAction.showToast({message: `图片识别失败 ${err.message ?? ''}`, shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
    } finally {
      this.ocrLoading = false;
    }
  }

  applyOnDeviceAi() {
    const intent = OnDeviceAccountingAiService.parse(this.smartText);
    if (!intent) {
      promptAction.showToast({message: '未识别到金额或分类', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
      return;
    }
    this.selectedTag = intent.tag;
    this.parsedAmount = intent.amount;
    this.currentMenu = 'money';
    promptAction.showToast({message: `已识别 ${intent.tag.name} ¥${intent.amount}`, shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#a6f499'})
  }

  saveReceiptItems() {
    if (!this.appToken || this.userId === 'local') {
      promptAction.showToast({message: '请先登录华为账号', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
      return;
    }
    if (this.receiptItems.length === 0) {
      return;
    }
    BitstripeApiService.batchCreateRecords(this.appToken, this.receiptItems).then(() => {
      this.receiptItems = [];
      this.smartText = '';
      this.parsedAmount = '';
      this.selectedTag = null;
      this.syncWithServer();
      promptAction.showToast({message: '票据项目已入账', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#a6f499'})
    }).catch((error: BusinessError) => {
      promptAction.showToast({message: `批量入账失败 ${error.message ?? ''}`, shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
    });
  }

  build() {
    RelativeContainer() {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween }) {
        if (this.currentMenu === 'home') {
          this.homeBuilder()
        } else if (this.currentMenu === 'money') {
          this.countBuilder()
        } else if (this.currentMenu === 'statistics') {
          this.statisticsBuilder()
        } else if (this.currentMenu === 'wishlist') {
          this.wishlistBuilder()
        } else {
          this.settingsBuilder()
        }

        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
          ForEach(['home', 'money', 'statistics', 'wishlist', 'settings'], (item: string) => {
            Column() {
              Image($rawfile(`icons/${this.getMenuIcon(item)}`))
                .width(24)
                .height(24)
                .fillColor(item === this.currentMenu ? '#a3c6bf' : '#d7e0e2')
              Text(this.getMenuTitle(item))
                .fontSize(12)
                .fontColor(item === this.currentMenu ? '#a3c6bf' : '#d7e0e2')
                .padding({ top: 10 })
            }
            .width('20%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentMenu = item;
            })
          }, (item: string) => item)
        }
        .height(68)
        .padding({ top: 5, bottom: 5 })
        .width('100%')
        .backgroundColor('#f7f8f3')
      }
      .width('100%')
      .height('100%')
    }
  }
}
