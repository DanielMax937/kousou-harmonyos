import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { BitstripeApiService, ServerTag, ServerTagPayload } from '../../common/server/BitstripeApiService';

export interface Tag {
  id: number,
  name: string,
  icon: string,
  category: string,
  isDefault?: boolean,
  isUserTag?: boolean,
}

export const INIT_TAG: Tag[] = [
  { id: 1, name: '餐饮', icon: 'canyin', category: 'cost', isDefault: true },
  { id: 2, name: '水果', icon: 'fruit', category: 'cost', isDefault: true },
  { id: 3, name: '蔬菜', icon: 'shucai', category: 'cost', isDefault: true },
  { id: 4, name: '饮料', icon: 'yinliao', category: 'cost', isDefault: true },
  { id: 5, name: '冰淇淋', icon: 'ice-cream', category: 'cost', isDefault: true },
  { id: 6, name: '小车', icon: 'xiaoche', category: 'cost', isDefault: true },
  { id: 7, name: '出租车', icon: 'taxi', category: 'cost', isDefault: true },
  { id: 8, name: '出租', icon: 'chuzuche', category: 'cost', isDefault: true },
  { id: 9, name: '公交车', icon: 'gongjiao', category: 'cost', isDefault: true },
  { id: 10, name: '火车', icon: 'train', category: 'cost', isDefault: true },
  { id: 11, name: '飞机', icon: 'feiji', category: 'cost', isDefault: true },
  { id: 12, name: '加油', icon: 'jiayou', category: 'cost', isDefault: true },
  { id: 13, name: '电动车', icon: 'diandongche', category: 'cost', isDefault: true },
  { id: 14, name: '购物', icon: 'shopping', category: 'cost', isDefault: true },
  { id: 15, name: '商场', icon: 'shop', category: 'cost', isDefault: true },
  { id: 16, name: '衣服', icon: 'yifu', category: 'cost', isDefault: true },
  { id: 17, name: '鞋子', icon: 'shoes', category: 'cost', isDefault: true },
  { id: 18, name: '牛仔裤', icon: 'jeans', category: 'cost', isDefault: true },
  { id: 19, name: '裤子', icon: 'kuzi', category: 'cost', isDefault: true },
  { id: 20, name: '包', icon: 'bag', category: 'cost', isDefault: true },
  { id: 21, name: '口红', icon: 'kouhong', category: 'cost', isDefault: true },
  { id: 22, name: '玩具', icon: 'wanju', category: 'cost', isDefault: true },
  { id: 23, name: '儿童玩具', icon: 'toy', category: 'cost', isDefault: true },
  { id: 24, name: '房租', icon: 'fangzu', category: 'cost', isDefault: true },
  { id: 25, name: '水电', icon: 'shuidian', category: 'cost', isDefault: true },
  { id: 26, name: '电费', icon: 'electric', category: 'cost', isDefault: true },
  { id: 27, name: '燃气', icon: 'gas', category: 'cost', isDefault: true },
  { id: 28, name: '沙发', icon: 'shafa', category: 'cost', isDefault: true },
  { id: 29, name: '日用品', icon: 'riyong', category: 'cost', isDefault: true },
  { id: 30, name: '电脑', icon: 'diannao', category: 'cost', isDefault: true },
  { id: 31, name: '笔记本', icon: 'laptop', category: 'cost', isDefault: true },
  { id: 32, name: '手机', icon: 'phone', category: 'cost', isDefault: true },
  { id: 33, name: '工具', icon: 'tools', category: 'cost', isDefault: true },
  { id: 34, name: '医院', icon: 'yiyuan', category: 'cost', isDefault: true },
  { id: 35, name: '病床', icon: 'bingchuang', category: 'cost', isDefault: true },
  { id: 36, name: '医生', icon: 'yisheng', category: 'cost', isDefault: true },
  { id: 37, name: '药丸', icon: 'yaowan', category: 'cost', isDefault: true },
  { id: 38, name: '牙齿', icon: 'yachi', category: 'cost', isDefault: true },
  { id: 39, name: '健康', icon: 'health', category: 'cost', isDefault: true },
  { id: 40, name: '心电图', icon: 'xindiantu', category: 'cost', isDefault: true },
  { id: 41, name: '针', icon: 'zhen', category: 'cost', isDefault: true },
  { id: 42, name: '教育', icon: 'education', category: 'cost', isDefault: true },
  { id: 43, name: '书籍', icon: 'book', category: 'cost', isDefault: true },
  { id: 44, name: '书本', icon: 'shuben', category: 'cost', isDefault: true },
  { id: 45, name: '学校', icon: 'xuexiao', category: 'cost', isDefault: true },
  { id: 46, name: '老师', icon: 'laoshi', category: 'cost', isDefault: true },
  { id: 47, name: '练习册', icon: 'lianxice', category: 'cost', isDefault: true },
  { id: 48, name: '娱乐', icon: 'youxi', category: 'cost', isDefault: true },
  { id: 49, name: '电影', icon: 'movie', category: 'cost', isDefault: true },
  { id: 50, name: '电影院', icon: 'dianying', category: 'cost', isDefault: true },
  { id: 51, name: '音乐', icon: 'yinyue', category: 'cost', isDefault: true },
  { id: 52, name: '游戏', icon: 'game', category: 'cost', isDefault: true },
  { id: 53, name: '派对', icon: 'party', category: 'cost', isDefault: true },
  { id: 54, name: '票', icon: 'ticket', category: 'cost', isDefault: true },
  { id: 55, name: '旅行', icon: 'travel', category: 'cost', isDefault: true },
  { id: 56, name: '旅游', icon: 'lvyou', category: 'cost', isDefault: true },
  { id: 57, name: '游轮', icon: 'youlun', category: 'cost', isDefault: true },
  { id: 58, name: '健身', icon: 'fitness', category: 'cost', isDefault: true },
  { id: 59, name: '肌肉', icon: 'muscle', category: 'cost', isDefault: true },
  { id: 60, name: '游泳', icon: 'swimming', category: 'cost', isDefault: true },
  { id: 61, name: '篮球', icon: 'lanqiu', category: 'cost', isDefault: true },
  { id: 62, name: '宠物', icon: 'chongwu', category: 'cost', isDefault: true },
  { id: 63, name: '礼物', icon: 'liwu', category: 'cost', isDefault: true },
  { id: 64, name: '违章', icon: 'weizhang', category: 'cost', isDefault: true },
  { id: 65, name: '婴儿车', icon: 'yingerche', category: 'cost', isDefault: true },
  { id: 66, name: '奶瓶', icon: 'naiping', category: 'cost', isDefault: true },
  { id: 67, name: '工资', icon: 'gongji', category: 'income', isDefault: true },
  { id: 68, name: '奖金', icon: 'jiangjin', category: 'income', isDefault: true },
  { id: 69, name: '投资', icon: 'invest', category: 'income', isDefault: true },
  { id: 70, name: '分红', icon: 'fenhong', category: 'income', isDefault: true },
  { id: 71, name: '礼金', icon: 'hongbao', category: 'income', isDefault: true },
  { id: 72, name: '红包', icon: 'hongbao', category: 'income', isDefault: true },
  { id: 73, name: '报销', icon: 'baoxiao', category: 'income', isDefault: true },
  { id: 74, name: '工作', icon: 'job', category: 'income', isDefault: true },
  { id: 75, name: '补助', icon: 'buzhu', category: 'income', isDefault: true },
  { id: 76, name: '股票', icon: 'stock', category: 'income', isDefault: true },
  { id: 77, name: '银行', icon: 'bank', category: 'income', isDefault: true },
  { id: 78, name: '借款', icon: 'jiekuan', category: 'income', isDefault: true },
  { id: 79, name: '钱包', icon: 'wallet', category: 'income', isDefault: true },
]

@Component
export struct Money {
  @State moneyType: string = 'cost';
  @Link selectedTag: Tag | null;
  @Link userId: string;
  @Link appToken: string;

  @State tagList: Tag[] = INIT_TAG;
  @State showAddTagPanel: boolean = false;
  @State newTagName: string = '';
  @State selectedIcon: string = 'riyong';
  getSelectedColor = (currentType: string) => {
    if(currentType !== this.moneyType) {
      return '#e8ecef'
    } else {
      return '#fff'
    }
  }

  getCurrentTypeTag = () => {
    return this.tagList.filter((item)=> {
      return item.category == this.moneyType
    })
  }

  getIconOptions = () => {
    const names: string[] = [];
    INIT_TAG.filter((item: Tag) => item.category === this.moneyType).forEach((item: Tag) => {
      if (!names.includes(item.icon)) {
        names.push(item.icon);
      }
    });
    return names.slice(0, 18);
  }

  getCurrentTypeTagIndex = () => {
    return this.tagList.filter((item)=> {
      return item.category == this.moneyType
    }).map((_, index)=> {
      return index;
    })
  }

  getIconStr = (name: string) => {
    return 'icons/tags/'+name+'.svg';
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
      console.warn(`[Money] toast skipped, code=${err.code}, message=${err.message}`);
    }
  }

  selectMoneyType(type: string) {
    this.moneyType = type;
    this.selectedIcon = type === 'income' ? 'gongji' : 'riyong';
  }

  addCustomTag() {
    const tagName = this.newTagName.trim();
    if (!tagName) {
      this.showToast('请输入分类名称', '#ffcac8');
      return;
    }
    const exists = INIT_TAG.some((item: Tag) => item.name === tagName && item.category === this.moneyType);
    if (exists) {
      this.showToast('分类已存在', '#ffcac8');
      return;
    }
    if (this.appToken && this.userId !== 'local') {
      const payload: ServerTagPayload = {
        name: tagName,
        icon: this.selectedIcon,
        type: this.moneyType
      };
      BitstripeApiService.createTag(this.appToken, payload).then((tag: ServerTag) => {
        const newTag: Tag = {
          id: tag.id,
          name: tag.name,
          icon: tag.icon || this.selectedIcon,
          category: tag.type,
          isDefault: tag.isDefault,
          isUserTag: !tag.isDefault
        };
        INIT_TAG.push(newTag);
        this.tagList = INIT_TAG.slice();
        this.selectedTag = newTag;
        this.newTagName = '';
        this.showAddTagPanel = false;
        this.showToast('分类已保存到服务端', '#a6f499');
      }).catch((error: BusinessError) => {
        this.showToast(`分类保存失败 ${error.message ?? ''}`, '#ffcac8');
      });
      return;
    }
    const newTag: Tag = {
      id: 1000 + INIT_TAG.length,
      name: tagName,
      icon: this.selectedIcon,
      category: this.moneyType,
      isDefault: false,
      isUserTag: true
    };
    INIT_TAG.push(newTag);
    this.tagList = INIT_TAG.slice();
    this.selectedTag = newTag;
    this.newTagName = '';
    this.showAddTagPanel = false;
    this.showToast('分类已添加到本机，登录后可保存到服务端', '#a6f499');
  }

  getSelectedTagColor = (target: Tag) => {
    if(this.selectedTag) {
      if(target.id === this.selectedTag.id) {
        return '#95c8be'
      }
    }
    return 'transparent'
  }

  getSelectedTagBgColor = (target: Tag) => {
    if(this.selectedTag) {
      if(target.id === this.selectedTag.id) {
        return '#a0ded1'
      }
    }
    return 'transparent'


  }

  build() {
    Column() {
      Row() {
        Text("记一笔")
          .fontColor('#010101')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({left: 10})
        Row() {
          Text("收入")
            .padding({top: 3, bottom: 3, left: 8, right: 8})
            .border({radius: 4})
            .backgroundColor(this.getSelectedColor('income'))
            .fontSize(14)
            .onClick(()=> {
              this.selectMoneyType('income')
            })
          Text("支出")
            .padding({top: 3, bottom: 3, left: 8, right: 8})
            .border({radius: 4})
            .backgroundColor(this.getSelectedColor('cost'))
            .fontSize(14)
            .onClick(()=> {
              this.selectMoneyType('cost')
            })
        }
        .padding(2)
        .border({radius: 4})
        .backgroundColor("#e8ecef")
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding({top: 10, bottom: 10, right: 20, left: 20})
      Scroll() {
        Flex({justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap}) {
          Column(){
            Text('+')
              .fontSize(28)
              .fontColor('#2f7468')
            Text('新增')
              .fontSize(14)
          }
          .justifyContent(FlexAlign.Center)
          .width('calc(20% - 8px)')
          .margin({top: 4, bottom: 0, left: 4, right: 4})
          .padding({top: 4, bottom: 4, left: 8, right: 8})
          .border({radius: 8, width: 2, color: '#dce7e2', style: BorderStyle.Solid})
          .backgroundColor('#fff')
          .onClick(() => {
            this.showAddTagPanel = !this.showAddTagPanel;
          })
          ForEach(this.getCurrentTypeTagIndex(), (item: string) => {
              Column(){
                Image($rawfile(this.getIconStr(this.getCurrentTypeTag()[parseInt(item)].icon)))
                  .width(40)
                  .height(40)
                Text(this.getCurrentTypeTag()[parseInt(item)].name)
                  .fontSize(14)
              }
                .justifyContent(FlexAlign.Center)
                .width('calc(20% - 8px)')
                .margin({top: 4, bottom: 0, left: 4, right: 4})
                .padding({top: 4, bottom: 4, left: 8, right: 8})
                .border({radius: 8, width: 2, color: this.getSelectedTagColor(this.getCurrentTypeTag()[parseInt(item)]), style: BorderStyle.Solid})
                .backgroundColor(this.getSelectedTagBgColor(this.getCurrentTypeTag()[parseInt(item)]))
            .onClick(() => {
              const target = this.getCurrentTypeTag()[parseInt(item)];
              this.selectedTag = target;
            })
          }, (item: string) => item)
        }
        .padding({top: 4, bottom: 12, left: 16, right: 16})
        .backgroundColor('#f9faf5')
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)

      if (this.showAddTagPanel) {
        Column() {
          TextInput({ placeholder: '分类名称', text: this.newTagName })
            .height(38)
            .fontSize(14)
            .backgroundColor('#fff')
            .border({ radius: 8 })
            .onChange((value: string) => {
              this.newTagName = value;
            })
          Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            ForEach(this.getIconOptions(), (icon: string) => {
              Image($rawfile(this.getIconStr(icon)))
                .width(34)
                .height(34)
                .padding(5)
                .margin({ right: 7, top: 7 })
                .backgroundColor(this.selectedIcon === icon ? '#a1e0cf' : '#edf0ec')
                .border({ radius: 8 })
                .onClick(() => {
                  this.selectedIcon = icon;
                })
            }, (icon: string) => icon)
          }
          .width('100%')
          Row() {
            Button('取消')
              .height(36)
              .layoutWeight(1)
              .backgroundColor('#edf0ec')
              .fontColor('#1f2f2b')
              .onClick(() => {
                this.showAddTagPanel = false;
              })
            Button('保存分类')
              .height(36)
              .layoutWeight(1)
              .margin({ left: 8 })
              .backgroundColor('#f1c21a')
              .fontColor('#222')
              .onClick(() => {
                this.addCustomTag();
              })
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 18, right: 18, top: 8, bottom: 8 })
        .backgroundColor('#f2f5f0')
      }
    }
    .width('100%')
    .height('100%')
  }
}
