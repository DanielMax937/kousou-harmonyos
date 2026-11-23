import { Home } from './components/Home'
import { INIT_TAG, Money, Tag } from './components/Money';
import { MyKeyboard } from './components/MyKeyboard';
import { Settings } from './components/Settings';
import { Statistics } from './components/Statistics';
import { Wishlist } from './components/Wishlist';
import { promptAction, router } from '@kit.ArkUI';
import RdbUtils from '../common/rdbUtils/RdbUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
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
        Text('今天')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .height(44)
          .align(Alignment.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#010101')
      }

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
        .margin({ top: 4, bottom: 4 })
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .backgroundColor('#fff')
        .border({ radius: 8, width: 1, color: '#edf0ec' })
      }

      Home({
        currentMenu: $currentMenu,
        userId: $userId,
        syncRevision: $syncRevision,
        ocrLoading: this.ocrLoading,
        onRecognizeImage: (): void => {
          this.recognizeReceiptImage();
        }
      })
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
        appToken: $appToken,
        currentMenu: $currentMenu
      })
        .layoutWeight(1)

      TextInput({ placeholder: '备注，例如：和朋友午餐、客户报销', text: this.noteText })
        .height(42)
        .fontSize(14)
        .fontColor('#111')
        .placeholderColor('#7d8985')
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
        .height(248)
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
    this.restoreSavedAuth();
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
    this.userId = 'local';
    this.appToken = '';
    this.accountLabel = '未登录';
    router.replaceUrl({
      url: CommonConstants.LOGIN_PAGE_URL,
      params: CommonConstants.loginGateParams()
    }).catch((error: BusinessError) => {
      console.error(`[Index] redirect to login failed, code=${error.code}, message=${error.message}`);
    });
  }

  goLogin() {
    router.pushUrl({ url: CommonConstants.LOGIN_PAGE_URL });
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
        this.goLogin();
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
          type: item.type === 'income' ? 'income' : 'cost',
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
      this.goLogin();
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
                .fillColor(item === this.currentMenu ? '#2f7468' : '#8d9996')
              Text(this.getMenuTitle(item))
                .fontSize(12)
                .fontColor(item === this.currentMenu ? '#2f7468' : '#8d9996')
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
