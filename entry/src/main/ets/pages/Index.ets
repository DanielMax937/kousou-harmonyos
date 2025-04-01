import { Home } from './components/Home'
import { LayoutComponent } from './components/Layout'
import { Money, Tag } from './components/Money';
import { MyKeyboard } from './components/MyKeyboard';
import { promptAction } from '@kit.ArkUI';
import RdbUtils from '../common/rdbUtils/RdbUtils';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State currentMenu: string = 'home';
  @State selectedTag: Tag | null = null;

  changeTab: (key:string) => void = (key:string) => {
    this.currentMenu = key;
  }

  @Builder homeBuilder() {
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
    Home({ changeTab: this.changeTab})
  }

  @Builder countBuilder() {
    Column(){
      Money({
        updateTag: (data: Tag) => {
          this.selectedTag = data;
        },
        selectedTag: this.selectedTag
      })
        .height('50%')

      MyKeyboard({ saveRecord: (amount:string) => {
        if(!this.selectedTag) {
          promptAction.showToast({message: '请先选择标签', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
          return false;
        }
        if(Number(amount || '0') <= 0) {
          promptAction.showToast({message: '请输入金额', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#ffcac8'})
          return false;
        }
        if(RdbUtils.getStore()) {
          RdbUtils.insert('ACCOUNT', {
            TAG: this.selectedTag.name,
            TYPE: this.selectedTag.category,
            AMOUNT: amount,
          }).then(()=> {
            promptAction.showToast({message: '记账成功', shadow: ShadowStyle.OUTER_DEFAULT_SM , alignment: Alignment.Top, backgroundColor: '#a6f499'})
            this.selectedTag = null;
            return true;
          }).catch((err: BusinessError) => {
            console.log(`[RdbInfo]ExecuteSql failed, code is ${err.code},message is ${err.message}`);
          })
        }
        return true;
      } })
        .height('50%')
    }

  }

  build() {
    RelativeContainer() {
      LayoutComponent({
        currentMenu: this.currentMenu,
        changeTab: this.changeTab,
        homeBuilderParam: this.homeBuilder,
        countBuilderParam: this.countBuilder
      })
    }
  }
}