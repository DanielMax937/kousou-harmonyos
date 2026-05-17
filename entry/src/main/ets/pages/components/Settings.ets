import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import CommonConstants from '../../common/constants/CommonConstants';
import RdbUtils from '../../common/rdbUtils/RdbUtils';
import { BitstripeApiService, ServerInviteCode, ServerTag, ServerTagPayload } from '../../common/server/BitstripeApiService';
import { INIT_TAG, Tag } from './Money';

@Component
export struct Settings {
  @Link accountLabel: string;
  @Link userId: string;
  @Link appToken: string;
  @Link serverHost: string;

  @State versionTapCount: number = 0;
  @State showHiddenSettings: boolean = false;
  @State draftHost: string = '';
  @State inviteCode: string = '';
  @State customTagName: string = '';
  @State customTagType: string = 'cost';
  @State customTagIcon: string = 'riyong';
  @State editingTagId: number = 0;
  @State displayName: string = '';
  @State adminInviteCode: string = '';
  @State adminInviteMaxUses: string = '3';
  @State inviteCodes: ServerInviteCode[] = [];
  @State inviteAdminOpen: boolean = false;

  aboutToAppear() {
    this.draftHost = this.serverHost || CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;
    this.displayName = this.accountLabel.replace('已登录 ', '');
    this.loadServerTags();
    this.loadInviteCodes();
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

  redeemInvite() {
    if (!this.appToken || this.userId === 'local') {
      this.showToast('请先登录华为账号', '#ffcac8');
      return;
    }
    if (!this.inviteCode) {
      this.showToast('请输入邀请码', '#ffcac8');
      return;
    }
    BitstripeApiService.redeemInvite(this.appToken, this.inviteCode).then(() => {
      this.inviteCode = '';
      this.showToast('邀请码已生效', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`邀请码无效 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  logout() {
    const context = getContext(this) as common.UIAbilityContext;
    RdbUtils.clearKousouAuth(context).then(() => {
      this.accountLabel = '未登录';
      this.userId = 'local';
      this.appToken = '';
      this.displayName = '';
      this.showToast('已退出登录', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`退出失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  saveProfile() {
    if (!this.appToken || this.userId === 'local') {
      this.showToast('请先登录华为账号', '#ffcac8');
      return;
    }
    BitstripeApiService.updateProfile(this.appToken, {
      displayName: this.displayName
    }).then((profile) => {
      this.accountLabel = profile.displayName ? profile.displayName : `已登录 ${profile.userId}`;
      this.showToast('资料已保存', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`资料保存失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  loadServerTags() {
    if (!this.appToken || this.userId === 'local') {
      return;
    }
    BitstripeApiService.getTags(this.appToken).then((tags: ServerTag[]) => {
      tags.forEach((item: ServerTag) => {
        const exists = INIT_TAG.some((tag: Tag) => tag.name === item.name && tag.category === item.type);
        if (!exists) {
          INIT_TAG.push({
            id: item.id,
            name: item.name,
            icon: item.icon || (item.type === 'income' ? 'gongji' : 'riyong'),
            category: item.type,
            isDefault: item.isDefault,
            isUserTag: !item.isDefault
          });
        }
      });
    }).catch(() => {});
  }

  loadInviteCodes() {
    if (!this.appToken || this.userId === 'local') {
      return;
    }
    BitstripeApiService.getInviteCodes(this.appToken).then((codes: ServerInviteCode[]) => {
      this.inviteCodes = codes;
      this.inviteAdminOpen = codes.length > 0;
    }).catch(() => {});
  }

  createInviteCode() {
    if (!this.appToken || this.userId === 'local') {
      this.showToast('请先登录华为账号', '#ffcac8');
      return;
    }
    const maxUses = Math.max(1, Number(this.adminInviteMaxUses || '1'));
    BitstripeApiService.createInviteCode(this.appToken, {
      code: this.adminInviteCode.trim() || undefined,
      maxUses
    }).then((code: ServerInviteCode) => {
      this.adminInviteCode = '';
      this.adminInviteMaxUses = '3';
      this.inviteAdminOpen = true;
      this.loadInviteCodes();
      this.showToast(`邀请码已生成 ${code.code}`, '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`生成失败 ${error.message ?? '需要高级账号权限'}`, '#ffcac8');
    });
  }

  getIconStr(name: string): string {
    return 'icons/tags/' + name + '.svg';
  }

  iconOptions(): string[] {
    const names: string[] = [];
    INIT_TAG.filter((item: Tag) => item.category === this.customTagType).forEach((item: Tag) => {
      if (!names.includes(item.icon)) {
        names.push(item.icon);
      }
    });
    return names.slice(0, 18);
  }

  addCustomTag() {
    if (!this.customTagName) {
      this.showToast('请输入分类名称', '#ffcac8');
      return;
    }
    const tagName = this.customTagName;
    const icon = this.customTagIcon || (this.customTagType === 'income' ? 'gongji' : 'riyong');
    if (this.appToken && this.userId !== 'local') {
      const payload: ServerTagPayload = {
        name: tagName,
        icon,
        type: this.customTagType
      };
      const wasEditing = this.editingTagId > 0;
      const request = wasEditing
        ? BitstripeApiService.updateTag(this.appToken, this.editingTagId, payload)
        : BitstripeApiService.createTag(this.appToken, payload);
      request.then((tag: ServerTag) => {
        const exists = INIT_TAG.some((item: Tag) => item.id === tag.id || (item.name === tag.name && item.category === tag.type));
        if (!exists) {
          INIT_TAG.push({
            id: tag.id,
            name: tag.name,
            icon: tag.icon || icon,
            category: tag.type,
            isDefault: tag.isDefault,
            isUserTag: !tag.isDefault
          });
        } else {
          INIT_TAG.forEach((item: Tag) => {
            if (item.id === tag.id) {
              item.name = tag.name;
              item.icon = tag.icon || icon;
              item.category = tag.type;
            }
          });
        }
        this.customTagName = '';
        this.customTagIcon = this.customTagType === 'income' ? 'gongji' : 'riyong';
        this.editingTagId = 0;
        this.showToast(wasEditing ? '分类已更新' : '分类已保存到服务端', '#a6f499');
      }).catch((error: BusinessError) => {
        this.showToast(`分类保存失败 ${error.message ?? ''}`, '#ffcac8');
      });
      return;
    }
    const exists = INIT_TAG.some((item: Tag) => item.name === tagName && item.category === this.customTagType);
    if (!exists) {
      INIT_TAG.push({
        id: 1000 + INIT_TAG.length,
        name: tagName,
        icon,
        category: this.customTagType,
        isDefault: false,
        isUserTag: true
      });
    }
    this.customTagName = '';
    this.customTagIcon = this.customTagType === 'income' ? 'gongji' : 'riyong';
    this.showToast('分类已添加到本机，登录后可保存到服务端', '#a6f499');
  }

  editTag(tag: Tag) {
    if (tag.isDefault) {
      return;
    }
    this.editingTagId = tag.id;
    this.customTagName = tag.name;
    this.customTagType = tag.category;
    this.customTagIcon = tag.icon;
  }

  deleteTag(tag: Tag) {
    if (tag.isDefault) {
      this.showToast('默认分类不能删除', '#ffcac8');
      return;
    }
    if (!this.appToken || this.userId === 'local') {
      const index = INIT_TAG.findIndex((item: Tag) => item.id === tag.id);
      if (index >= 0) {
        INIT_TAG.splice(index, 1);
      }
      this.showToast('本机分类已删除', '#a6f499');
      return;
    }
    BitstripeApiService.deleteTag(this.appToken, tag.id).then(() => {
      const index = INIT_TAG.findIndex((item: Tag) => item.id === tag.id);
      if (index >= 0) {
        INIT_TAG.splice(index, 1);
      }
      this.showToast('分类已删除', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`删除失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  tagTypeBg(type: string): string {
    return this.customTagType === type ? '#a1e0cf' : '#edf0ec';
  }

  selectTagType(type: string) {
    this.customTagType = type;
    this.customTagIcon = type === 'income' ? 'gongji' : 'riyong';
  }

  build() {
    Scroll() {
      Column() {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ top: 24, bottom: 18 })

        Column() {
          Text(this.accountLabel)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
          Text(this.userId === 'local' ? '本地模式' : `用户 ID ${this.userId}`)
            .fontSize(13)
            .fontColor('#66736f')
            .margin({ top: 4 })
          if (this.userId !== 'local') {
            TextInput({ placeholder: '昵称', text: this.displayName })
              .height(40)
              .fontSize(14)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.displayName = value;
              })
            Row() {
              Button('保存资料')
                .height(38)
                .layoutWeight(1)
                .backgroundColor('#a1e0cf')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.saveProfile();
                })
              Button('退出登录')
                .height(38)
                .layoutWeight(1)
                .margin({ left: 8 })
                .backgroundColor('#edf0ec')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.logout();
                })
            }
            .width('100%')
            .margin({ top: 10 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 14, bottom: 14, left: 16, right: 16 })
        .backgroundColor('#f2f5f0')
        .border({ radius: 8 })

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

        Column() {
          Text('邀请码')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
            .width('100%')
          Row() {
            TextInput({ placeholder: '输入邀请码', text: this.inviteCode })
              .height(42)
              .fontSize(14)
              .layoutWeight(1)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .onChange((value: string) => {
                this.inviteCode = value;
              })
            Button('兑换')
              .height(42)
              .margin({ left: 8 })
              .backgroundColor('#a1e0cf')
              .fontColor('#1f2f2b')
              .onClick(() => {
                this.redeemInvite();
              })
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 18, bottom: 18 })

        Column() {
          Row() {
            Text('管理员邀请码')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111')
            Text(this.inviteAdminOpen ? '收起' : '生成')
              .fontSize(14)
              .fontColor('#2f7468')
              .onClick(() => {
                this.inviteAdminOpen = !this.inviteAdminOpen;
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')

          if (this.inviteAdminOpen) {
            Row() {
              TextInput({ placeholder: '邀请码，可留空自动生成', text: this.adminInviteCode })
                .height(42)
                .fontSize(14)
                .layoutWeight(1)
                .backgroundColor('#fff')
                .border({ radius: 8 })
                .onChange((value: string) => {
                  this.adminInviteCode = value;
                })
              TextInput({ placeholder: '次数', text: this.adminInviteMaxUses })
                .height(42)
                .width(72)
                .fontSize(14)
                .margin({ left: 8 })
                .backgroundColor('#fff')
                .border({ radius: 8 })
                .onChange((value: string) => {
                  this.adminInviteMaxUses = value;
                })
            }
            .width('100%')
            .margin({ top: 10 })
            Button('生成邀请码')
              .height(40)
              .width('100%')
              .margin({ top: 8 })
              .backgroundColor('#f1c21a')
              .fontColor('#222')
              .onClick(() => {
                this.createInviteCode();
              })
            ForEach(this.inviteCodes.slice(0, 5), (item: ServerInviteCode) => {
              Row() {
                Text(item.code)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111')
                Text(`${item.usesCount}/${item.maxUses}`)
                  .fontSize(12)
                  .fontColor('#66736f')
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .border({ width: { bottom: 1 }, color: '#edf0ec' })
            }, (item: ServerInviteCode) => item.code)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 18, bottom: 18 })

        Column() {
          Text('分类管理')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
            .width('100%')
          Row() {
            Text('支出')
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .width('48%')
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(this.tagTypeBg('cost'))
              .border({ radius: 6 })
              .onClick(() => {
                this.selectTagType('cost');
              })
            Text('收入')
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .width('48%')
              .padding({ top: 8, bottom: 8 })
              .backgroundColor(this.tagTypeBg('income'))
              .border({ radius: 6 })
              .onClick(() => {
                this.selectTagType('income');
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .margin({ top: 10 })
          Row() {
            TextInput({ placeholder: '新增分类名称', text: this.customTagName })
              .height(42)
              .fontSize(14)
              .layoutWeight(1)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .onChange((value: string) => {
                this.customTagName = value;
              })
            Button('添加')
              .height(42)
              .margin({ left: 8 })
              .backgroundColor('#f1c21a')
              .fontColor('#222')
              .onClick(() => {
                this.addCustomTag();
              })
          }
          .width('100%')
          .margin({ top: 10 })
          Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            ForEach(this.iconOptions(), (icon: string) => {
              Image($rawfile(this.getIconStr(icon)))
                .width(34)
                .height(34)
                .padding(5)
                .margin({ right: 7, top: 8 })
                .backgroundColor(this.customTagIcon === icon ? '#a1e0cf' : '#edf0ec')
                .border({ radius: 8 })
                .onClick(() => {
                  this.customTagIcon = icon;
                })
            }, (icon: string) => icon)
          }
          .width('100%')
          Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            ForEach(INIT_TAG, (item: Tag) => {
              Row() {
                Text(item.name)
                  .fontSize(12)
                  .fontColor(item.isDefault ? '#66736f' : '#1f2f2b')
                if (!item.isDefault) {
                  Text('编辑')
                    .fontSize(11)
                    .fontColor('#2f7468')
                    .margin({ left: 6 })
                    .onClick(() => {
                      this.editTag(item);
                    })
                  Text('删')
                    .fontSize(11)
                    .fontColor('#b42318')
                    .margin({ left: 6 })
                    .onClick(() => {
                      this.deleteTag(item);
                    })
                }
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .margin({ right: 6, top: 8 })
              .backgroundColor(item.isDefault ? '#edf0ec' : '#dce7e2')
              .border({ radius: 6 })
            }, (item: Tag) => `${item.category}:${item.name}`)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 18, bottom: 18 })

        Row() {
          Text('版本号')
            .fontSize(16)
            .fontColor('#111')
          Text('1.0.5')
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
    .width('100%')
    .height('100%')
  }
}
