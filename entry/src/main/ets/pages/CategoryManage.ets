import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import CommonConstants, { CategoryManageRouteParams } from '../common/constants/CommonConstants';
import RdbUtils from '../common/rdbUtils/RdbUtils';
import { BitstripeApiService, ServerTag, ServerTagPayload } from '../common/server/BitstripeApiService';
import { INIT_TAG, Tag } from './components/Money';

@Entry
@Component
struct CategoryManage {
  @State userId: string = 'local';
  @State appToken: string = '';
  @State customTagName: string = '';
  @State customTagType: string = 'cost';
  @State customTagIcon: string = 'riyong';
  @State editingTagId: number = 0;
  @State isAdding: boolean = false;
  @State listRevision: number = 0;

  aboutToAppear() {
    this.applyRouteType();
    this.loadAuth();
  }

  applyRouteType() {
    const params = router.getParams() as CategoryManageRouteParams;
    if (params?.type === 'income' || params?.type === 'cost') {
      this.customTagType = params.type;
      this.customTagIcon = params.type === 'income' ? 'gongji' : 'riyong';
    }
  }

  loadAuth() {
    const context = getContext(this) as common.UIAbilityContext;
    RdbUtils.loadKousouAuth(context).then((auth) => {
      if (auth) {
        this.userId = auth.userId;
        this.appToken = auth.token;
        this.loadServerTags();
        return;
      }
      router.replaceUrl({
        url: CommonConstants.LOGIN_PAGE_URL,
        params: CommonConstants.loginGateParams()
      }).catch(() => {});
    }).catch(() => {});
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
      console.warn(`[CategoryManage] toast skipped, code=${err.code}, message=${err.message}`);
    }
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
      this.listRevision += 1;
    }).catch(() => {});
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

  filteredTags(): Tag[] {
    return INIT_TAG.filter((item: Tag) => item.category === this.customTagType);
  }

  showEditPanel(): boolean {
    return this.isAdding || this.editingTagId > 0;
  }

  tagItemBg(tag: Tag): string {
    if (this.editingTagId === tag.id) {
      return '#a1e0cf';
    }
    return tag.isDefault ? '#edf0ec' : '#f2f5f0';
  }

  tagItemBorder(tag: Tag): string {
    if (this.editingTagId === tag.id) {
      return '#2f7468';
    }
    return '#dce7e2';
  }

  selectTagType(type: string) {
    this.customTagType = type;
    this.customTagIcon = type === 'income' ? 'gongji' : 'riyong';
    this.cancelEdit();
  }

  startAddTag() {
    this.isAdding = true;
    this.editingTagId = 0;
    this.customTagName = '';
    this.customTagIcon = this.customTagType === 'income' ? 'gongji' : 'riyong';
  }

  editTag(tag: Tag) {
    if (tag.isDefault) {
      this.showToast('默认分类不可修改', '#ffcac8');
      return;
    }
    this.isAdding = false;
    this.editingTagId = tag.id;
    this.customTagName = tag.name;
    this.customTagIcon = tag.icon;
  }

  cancelEdit() {
    this.isAdding = false;
    this.editingTagId = 0;
    this.customTagName = '';
    this.customTagIcon = this.customTagType === 'income' ? 'gongji' : 'riyong';
  }

  bumpList() {
    this.listRevision += 1;
  }

  saveCustomTag() {
    if (!this.customTagName.trim()) {
      this.showToast('请输入分类名称', '#ffcac8');
      return;
    }
    const tagName = this.customTagName.trim();
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
        const index = INIT_TAG.findIndex((item: Tag) => item.id === tag.id);
        if (index >= 0) {
          INIT_TAG[index].name = tag.name;
          INIT_TAG[index].icon = tag.icon || icon;
          INIT_TAG[index].category = tag.type;
        } else {
          INIT_TAG.push({
            id: tag.id,
            name: tag.name,
            icon: tag.icon || icon,
            category: tag.type,
            isDefault: tag.isDefault,
            isUserTag: !tag.isDefault
          });
        }
        this.cancelEdit();
        this.bumpList();
        this.showToast(wasEditing ? '分类已更新' : '分类已保存', '#a6f499');
      }).catch((error: BusinessError) => {
        this.showToast(`分类保存失败 ${error.message ?? ''}`, '#ffcac8');
      });
      return;
    }
    if (this.editingTagId > 0) {
      const index = INIT_TAG.findIndex((item: Tag) => item.id === this.editingTagId);
      if (index >= 0) {
        INIT_TAG[index].name = tagName;
        INIT_TAG[index].icon = icon;
      }
      this.cancelEdit();
      this.bumpList();
      this.showToast('分类已更新', '#a6f499');
      return;
    }
    const exists = INIT_TAG.some((item: Tag) => item.name === tagName && item.category === this.customTagType);
    if (exists) {
      this.showToast('分类已存在', '#ffcac8');
      return;
    }
    INIT_TAG.push({
      id: 1000 + INIT_TAG.length,
      name: tagName,
      icon,
      category: this.customTagType,
      isDefault: false,
      isUserTag: true
    });
    this.cancelEdit();
    this.bumpList();
    this.showToast('分类已添加到本机', '#a6f499');
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
      this.cancelEdit();
      this.bumpList();
      this.showToast('本机分类已删除', '#a6f499');
      return;
    }
    BitstripeApiService.deleteTag(this.appToken, tag.id).then(() => {
      const index = INIT_TAG.findIndex((item: Tag) => item.id === tag.id);
      if (index >= 0) {
        INIT_TAG.splice(index, 1);
      }
      this.cancelEdit();
      this.bumpList();
      this.showToast('分类已删除', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`删除失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  deleteEditingTag() {
    const tag = INIT_TAG.find((item: Tag) => item.id === this.editingTagId);
    if (tag) {
      this.deleteTag(tag);
    }
  }

  tagTypeBg(type: string): string {
    return this.customTagType === type ? '#a1e0cf' : '#edf0ec';
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .fontSize(22)
          .fontColor('#1f2f2b')
          .width(42)
          .height(36)
          .backgroundColor('#edf0ec')
          .onClick(() => {
            router.back();
          })
        Text('分类管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(42)
      }
      .width('100%')
      .padding({ top: 10, bottom: 8, left: 14, right: 14 })

      Row() {
        Text('支出')
          .fontSize(14)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(this.tagTypeBg('cost'))
          .border({ radius: 6 })
          .onClick(() => {
            this.selectTagType('cost');
          })
        Text('收入')
          .fontSize(14)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .margin({ left: 8 })
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(this.tagTypeBg('income'))
          .border({ radius: 6 })
          .onClick(() => {
            this.selectTagType('income');
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 8 })

      Scroll() {
        Column() {
          Text('已有分类')
            .fontSize(13)
            .fontColor('#66736f')
            .width('100%')
            .margin({ bottom: 8 })

          Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            Column() {
              Text('+')
                .fontSize(26)
                .fontColor('#2f7468')
              Text('新增')
                .fontSize(11)
                .fontColor('#66736f')
                .margin({ top: 4 })
            }
            .justifyContent(FlexAlign.Center)
            .width(64)
            .height(76)
            .margin({ right: 8, bottom: 8 })
            .border({ radius: 8, width: 2, color: '#dce7e2', style: BorderStyle.Solid })
            .backgroundColor('#fff')
            .onClick(() => {
              this.startAddTag();
            })

            ForEach(this.filteredTags(), (item: Tag) => {
              Column() {
                Image($rawfile(this.getIconStr(item.icon)))
                  .width(32)
                  .height(32)
                Text(item.name)
                  .fontSize(11)
                  .fontColor('#34413d')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
              }
              .justifyContent(FlexAlign.Center)
              .width(64)
              .height(76)
              .margin({ right: 8, bottom: 8 })
              .border({ radius: 8, width: 2, color: this.tagItemBorder(item), style: BorderStyle.Solid })
              .backgroundColor(this.tagItemBg(item))
              .onClick(() => {
                this.editTag(item);
              })
            }, (item: Tag) => `${this.listRevision}_${item.category}_${item.id}`)
          }
          .width('100%')

          if (this.showEditPanel()) {
            Column() {
              Text(this.isAdding ? '新增分类' : '编辑分类')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111')
                .width('100%')
                .margin({ bottom: 8 })

              TextInput({ placeholder: '分类名称', text: this.customTagName })
                .height(42)
                .fontSize(14)
                .fontColor('#111')
                .placeholderColor('#7d8985')
                .width('100%')
                .backgroundColor('#fff')
                .border({ radius: 8 })
                .onChange((value: string) => {
                  this.customTagName = value;
                })

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

              Row() {
                Button('取消')
                  .height(40)
                  .layoutWeight(1)
                  .backgroundColor('#edf0ec')
                  .fontColor('#1f2f2b')
                  .onClick(() => {
                    this.cancelEdit();
                  })
                Button('保存')
                  .height(40)
                  .layoutWeight(1)
                  .margin({ left: 8 })
                  .backgroundColor('#a1e0cf')
                  .fontColor('#1f2f2b')
                  .onClick(() => {
                    this.saveCustomTag();
                  })
                if (this.editingTagId > 0) {
                  Button('删除')
                    .height(40)
                    .layoutWeight(1)
                    .margin({ left: 8 })
                    .backgroundColor('#ffe8e6')
                    .fontColor('#b42318')
                    .onClick(() => {
                      this.deleteEditingTag();
                    })
                }
              }
              .width('100%')
              .margin({ top: 10 })
            }
            .width('100%')
            .padding({ top: 12, bottom: 4 })
            .margin({ top: 8 })
            .backgroundColor('#f9faf5')
            .border({ radius: 8 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .scrollBarColor(Color.Transparent)
      .scrollBarWidth(0)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }
}
