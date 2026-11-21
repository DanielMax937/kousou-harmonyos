import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import { HuaweiAccountService, HuaweiAccountSession } from '../common/account/HuaweiAccountService';
import CommonConstants, { LoginRouteParams } from '../common/constants/CommonConstants';
import RdbUtils from '../common/rdbUtils/RdbUtils';
import { BitstripeApiService } from '../common/server/BitstripeApiService';
import CustomDialogComponent from '../view/CustomDialogComponent';
import { GlobalContext } from '../common/utils/GlobalContext';
import Logger from '../common/utils/Logger';
@Entry
@Component
struct Login {
  private context?: common.UIAbilityContext;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogComponent({
      cancel: () => {
        this.onPrivacyCancel();
      },
      confirm: () => {
        this.onPrivacyConfirm();
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: CommonConstants.DIALOG_CONTROLLER_DY_OFFSET },
    customStyle: true,
    autoCancel: false
  });
  @State isGate: boolean = false;
  @State accountLabel: string = '未登录';
  @State userId: string = 'local';
  @State huaweiAccountId: string = '';
  @State huaweiOpenId: string = '';
  @State huaweiNickName: string = '';
  @State huaweiAvatarUri: string = '';
  @State huaweiEmail: string = '';
  @State appToken: string = '';
  @State displayName: string = '';
  @State serverHost: string = CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;
  @State tokenExpiresAt: number = 0;
  @State loading: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as LoginRouteParams;
    this.isGate = params?.mode === CommonConstants.LOGIN_GATE_MODE;
  }

  onPageShow() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.bootstrap();
  }

  onPrivacyCancel() {
    this.context?.terminateSelf();
  }

  onPrivacyConfirm() {
    this.savePrivacyAgreement(() => {
      this.proceedAfterPrivacy();
    });
  }

  savePrivacyAgreement(onSaved?: () => void) {
    preferences.getPreferences(getContext(this), CommonConstants.PREFERENCES_FILE_NAME).then((store: preferences.Preferences) => {
      store.put(CommonConstants.PREFERENCES_KEY_PRIVACY, false).then(() => {
        store.flush().then(() => {
          Logger.info(CommonConstants.LAUNCHER_PAGE_TAG, 'Privacy agreement saved on login page.');
          if (onSaved) {
            onSaved();
          }
        }).catch((err: Error) => {
          Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Flush privacy agreement failed, err: ' + err);
        });
      }).catch((err: Error) => {
        Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Save privacy agreement failed, err: ' + err);
      });
    }).catch((err: Error) => {
      Logger.error(CommonConstants.LAUNCHER_PAGE_TAG, 'Get preferences for privacy failed, err: ' + err);
    });
  }

  async ensurePrivacyAgreement(): Promise<boolean> {
    const store = await preferences.getPreferences(getContext(this), CommonConstants.PREFERENCES_FILE_NAME);
    const value = await store.get(CommonConstants.PREFERENCES_KEY_PRIVACY, true);
    if (value) {
      const isJumpPrivacy: boolean = (GlobalContext.getContext().getObject('isJumpPrivacy') as boolean) ?? false;
      if (!isJumpPrivacy) {
        this.dialogController.open();
      }
      return false;
    }
    GlobalContext.getContext().setObject('isJumpPrivacy', false);
    return true;
  }

  proceedAfterPrivacy() {
    if (this.isGate && this.appToken && this.userId !== 'local') {
      this.goToAppHome();
    }
  }

  async bootstrap() {
    await this.loadState();
    const agreed = await this.ensurePrivacyAgreement();
    if (agreed) {
      this.proceedAfterPrivacy();
    }
  }

  goToAppHome() {
    router.replaceUrl({ url: CommonConstants.INDEX_PAGE_URL }).catch((error: BusinessError) => {
      console.error(`[Login] redirect to home failed, code=${error.code}, message=${error.message}`);
    });
  }

  async loadState() {
    const context = getContext(this) as common.UIAbilityContext;
    this.serverHost = await RdbUtils.loadKousouServerHost(context, CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST);
    BitstripeApiService.setServerHost(this.serverHost);
    const savedAuth = await RdbUtils.loadKousouAuth(context);
    if (savedAuth) {
      this.userId = savedAuth.userId;
      this.huaweiAccountId = savedAuth.huaweiAccountId ?? '';
      this.huaweiOpenId = savedAuth.huaweiOpenId ?? '';
      this.huaweiNickName = savedAuth.huaweiNickName ?? '';
      this.huaweiAvatarUri = savedAuth.huaweiAvatarUri ?? '';
      this.huaweiEmail = savedAuth.huaweiEmail ?? '';
      this.appToken = savedAuth.token;
      this.accountLabel = this.huaweiAccountLabel();
      this.displayName = savedAuth.accountLabel.startsWith('已登录 ') ? savedAuth.accountLabel.replace('已登录 ', '') : '';
      this.tokenExpiresAt = savedAuth.expiresAt;
      return;
    }
    this.userId = 'local';
    this.huaweiAccountId = '';
    this.huaweiOpenId = '';
    this.huaweiNickName = '';
    this.huaweiAvatarUri = '';
    this.huaweiEmail = '';
    this.appToken = '';
    this.accountLabel = '未登录';
    this.displayName = '';
    this.tokenExpiresAt = 0;
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
      console.warn(`[Login] toast skipped, code=${err.code}, message=${err.message}`);
    }
  }

  async loginWithHuawei() {
    if (this.loading) {
      return;
    }
    this.loading = true;
    const context = getContext(this) as common.UIAbilityContext;
    try {
      const session = await HuaweiAccountService.login(context);
      await this.applySession(session);
      this.showToast('华为账号登录成功', '#a6f499');
      this.goToAppHome();
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(`华为账号登录失败 ${err.message ?? ''}`, '#ffcac8');
    } finally {
      this.loading = false;
    }
  }

  async applySession(session: HuaweiAccountSession) {
    if (!session.authorizationCode) {
      this.showToast('需要重新登录以获取服务端令牌', '#ffcac8');
      return;
    }
    const authResult = await BitstripeApiService.authHuawei(session);
    this.userId = authResult.userId;
    this.huaweiAccountId = authResult.huaweiSub || session.unionID || session.userId;
    this.huaweiOpenId = session.openID;
    this.huaweiNickName = session.nickName;
    this.huaweiAvatarUri = session.avatarUri;
    this.huaweiEmail = session.email;
    this.appToken = authResult.token;
    this.accountLabel = this.huaweiAccountLabel();
    this.displayName = session.nickName;
    this.tokenExpiresAt = authResult.expiresAt;
    const context = getContext(this) as common.UIAbilityContext;
    const lastSyncAt = await RdbUtils.getKousouLastSyncAt(context);
    await RdbUtils.saveKousouAuth(context, {
      userId: this.userId,
      huaweiAccountId: this.huaweiAccountId,
      huaweiOpenId: this.huaweiOpenId,
      huaweiNickName: this.huaweiNickName,
      huaweiAvatarUri: this.huaweiAvatarUri,
      huaweiEmail: this.huaweiEmail,
      token: this.appToken,
      expiresAt: authResult.expiresAt,
      accountLabel: this.accountLabel,
      lastSyncAt
    });
    await RdbUtils.migrateLocalRecordsToUser(this.userId);
  }

  saveProfile() {
    if (!this.appToken || this.userId === 'local') {
      this.showToast('请先登录华为账号', '#ffcac8');
      return;
    }
    BitstripeApiService.updateProfile(this.appToken, {
      displayName: this.displayName
    }).then((profile) => {
      this.accountLabel = this.huaweiAccountLabel();
      const context = getContext(this) as common.UIAbilityContext;
      RdbUtils.getKousouLastSyncAt(context).then((lastSyncAt: string) => {
        return RdbUtils.saveKousouAuth(context, {
          userId: this.userId,
          huaweiAccountId: this.huaweiAccountId,
          huaweiOpenId: this.huaweiOpenId,
          huaweiNickName: this.huaweiNickName,
          huaweiAvatarUri: this.huaweiAvatarUri,
          huaweiEmail: this.huaweiEmail,
          token: this.appToken,
          expiresAt: this.tokenExpiresAt,
          accountLabel: this.accountLabel,
          lastSyncAt
        });
      });
      this.showToast('资料已保存', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`资料保存失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  logout() {
    const context = getContext(this) as common.UIAbilityContext;
    RdbUtils.clearKousouAuth(context).then(() => {
      this.accountLabel = '未登录';
      this.userId = 'local';
      this.huaweiAccountId = '';
      this.huaweiOpenId = '';
      this.huaweiNickName = '';
      this.huaweiAvatarUri = '';
      this.huaweiEmail = '';
      this.appToken = '';
      this.displayName = '';
      this.tokenExpiresAt = 0;
      this.isGate = true;
      this.showToast('已退出登录', '#a6f499');
      router.replaceUrl({
        url: CommonConstants.LOGIN_PAGE_URL,
        params: CommonConstants.loginGateParams()
      }).catch((error: BusinessError) => {
        console.error(`[Login] redirect after logout failed, code=${error.code}, message=${error.message}`);
      });
    }).catch((error: BusinessError) => {
      this.showToast(`退出失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  confirmDeleteAccount() {
    if (!this.appToken || this.userId === 'local' || this.loading) {
      return;
    }
    AlertDialog.show({
      title: '确认注销账号',
      message: '注销后将永久删除您在云端保存的所有账单、自定义分类、心愿目标与分析记录，且无法恢复。确认继续吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认注销',
        fontColor: '#c93b3b',
        action: () => {
          this.deleteAccount();
        }
      }
    });
  }

  async deleteAccount() {
    if (!this.appToken || this.userId === 'local' || this.loading) {
      return;
    }
    this.loading = true;
    const context = getContext(this) as common.UIAbilityContext;
    const deletingUserId = this.userId;
    try {
      await BitstripeApiService.deleteAccount(this.appToken);
      await RdbUtils.clearUserRecords(deletingUserId).catch(() => {});
      await RdbUtils.clearKousouAuth(context);
      this.accountLabel = '未登录';
      this.userId = 'local';
      this.huaweiAccountId = '';
      this.huaweiOpenId = '';
      this.huaweiNickName = '';
      this.huaweiAvatarUri = '';
      this.huaweiEmail = '';
      this.appToken = '';
      this.displayName = '';
      this.tokenExpiresAt = 0;
      this.isGate = true;
      this.showToast('账号已注销', '#a6f499');
      router.replaceUrl({
        url: CommonConstants.LOGIN_PAGE_URL,
        params: CommonConstants.loginGateParams()
      }).catch((error: BusinessError) => {
        console.error(`[Login] redirect after deleteAccount failed, code=${error.code}, message=${error.message}`);
      });
    } catch (error) {
      const err = error as BusinessError;
      this.showToast(`注销失败 ${err.message ?? ''}`, '#ffcac8');
    } finally {
      this.loading = false;
    }
  }

  shortAccountId(value: string): string {
    if (!value) {
      return '';
    }
    if (value.length <= 16) {
      return value;
    }
    return `${value.slice(0, 8)}...${value.slice(value.length - 6)}`;
  }

  displayHuaweiId(): string {
    return this.huaweiAccountId || this.userId;
  }

  huaweiAccountLabel(): string {
    if (this.huaweiNickName) {
      return this.huaweiNickName;
    }
    return `华为账号 ${this.shortAccountId(this.displayHuaweiId())}`;
  }

  build() {
    Column() {
      if (!this.isGate) {
        Row() {
          Column() {
            Image($rawfile('icons/back.svg'))
              .width(22)
              .height(22)
              .fillColor('#1f2f2b')
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.back();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 14, top: 10, bottom: 4 })
      }

      Text(this.isGate ? '登录' : '账号与同步')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111')
        .width('100%')
        .textAlign(this.isGate ? TextAlign.Center : TextAlign.Start)
        .padding({
          left: 14,
          right: 14,
          top: this.isGate ? 10 : 0,
          bottom: 12
        })

      Scroll() {
        Column() {
          Column() {
          Text(this.userId === 'local' ? '本地模式' : '华为账号已登录')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
            .width('100%')
          Text(this.userId === 'local' ? '登录后可同步账单、心愿和自定义分类。' : this.huaweiAccountLabel())
            .fontSize(14)
            .fontColor('#66736f')
            .width('100%')
            .margin({ top: 8 })
          if (this.userId !== 'local' && this.huaweiEmail) {
            Text(this.huaweiEmail)
              .fontSize(12)
              .fontColor('#8d9996')
              .width('100%')
              .margin({ top: 6 })
          }
          if (this.userId !== 'local' && !this.huaweiNickName) {
            Text(`华为 ID ${this.shortAccountId(this.displayHuaweiId())}`)
              .fontSize(12)
              .fontColor('#8d9996')
              .width('100%')
              .margin({ top: 6 })
          }
          if (this.userId !== 'local') {
            Text('显示昵称')
              .fontSize(12)
              .fontColor('#66736f')
              .width('100%')
              .margin({ top: 18, bottom: 4 })
            TextInput({ placeholder: '用于应用内展示', text: this.displayName })
              .height(44)
              .fontSize(14)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .onChange((value: string) => {
                this.displayName = value;
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 18, bottom: 18, left: 16, right: 16 })
        .backgroundColor('#f2f5f0')
        .border({ radius: 8 })

        if (this.userId === 'local') {
          Button(this.loading ? '登录中...' : '华为账号登录')
            .height(44)
            .width('100%')
            .margin({ top: 16 })
            .backgroundColor('#a1e0cf')
            .fontColor('#1f2f2b')
            .onClick(() => {
              this.loginWithHuawei();
            })
        } else {
          Button('保存资料')
            .height(44)
            .width('100%')
            .margin({ top: 16 })
            .backgroundColor('#a1e0cf')
            .fontColor('#1f2f2b')
            .onClick(() => {
              this.saveProfile();
            })
          Button('退出登录')
            .height(44)
            .width('100%')
            .margin({ top: 10 })
            .backgroundColor('#edf0ec')
            .fontColor('#1f2f2b')
            .onClick(() => {
              this.logout();
            })
        }

        Text('同步会保存账单记录、心愿计划和自定义分类。未登录时，数据继续保存在本机。')
          .fontSize(13)
          .fontColor('#66736f')
          .lineHeight(21)
          .width('100%')
          .margin({ top: 18 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 14, right: 14, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .scrollBarColor(Color.Transparent)
      .scrollBarWidth(0)
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f9faf5')
  }
}
