import { promptAction } from '@kit.ArkUI';
import RdbUtils, { AccountRecordInput } from '../../common/rdbUtils/RdbUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { BitstripeApiService } from '../../common/server/BitstripeApiService';
import { Tag } from './Money';

@CustomDialog
struct CustomDialogExample {
  controller: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({}),
  })

  build() {
    Column() {
      Text('我是内容')
        .fontSize(20)
        .margin({ top: 10, bottom: 10 })
    }
  }
}

@Component
export struct MyKeyboard {

  @State idx: string[] = [
    '',
    '1', '2', '3', '删除',
    '4', '5', '6', '+',
    '7', '8', '9', '-',
    '.', '0', '清零', '完成',
  ];

  @State totalValue: string = '0';

  @Link selectedTag: Tag | null;
  @Watch('handleParsedAmountChange') @Link parsedAmount: string;
  @Link smartText: string;
  @Link noteText: string;
  @Link userId: string;
  @Link appToken: string;
  @Link currentMenu: string;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample(),
  })

  aboutToAppear() {
    this.handleParsedAmountChange();
  }

  handleParsedAmountChange() {
    if (this.parsedAmount) {
      this.totalValue = this.parsedAmount;
    }
  }

  transArray = (strArr: Array<string>) => {
    strArr.forEach((str, index) => {
      if(str === '') {
        strArr[index] = '0'
      }
    })

    return strArr.reduce((arr: Array<string>, val) => {
      // 数组最后一个是符号
      if(/(\+|-)/.test(val) || arr.length === 0){
        arr.push(val)
      } else {
        arr[arr.length-1] = arr[arr.length-1] + val
      }
      return arr
    }, [])
  }

  updateOutput: (text: string, output: string) => string = (text: string, output: string) => {
        if(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].includes(text)) {
          if(output === '0') {
            return text;
          } else if(/([+-])0$/.test(output)) {
            return output.slice(0, -1) + text
          } else {
            return output + text;
          }
        } else if(text === '+') {
          if(/\.$/.test(output)) {
          return output + '0' + text;
        } else if(/\D$/.test(output)){
          return output.slice(0, -1) + text
        } else if(output === '0') {
          return output
        } else {
          return output + text
        }
        } else if(text === '-') {
           if(/\.$/.test(output)) {
          return output + '0' + text;
        } else if(/\D$/.test(output)){
          return output.slice(0, -1) + text
        } else if(output === '0') {
          return '-'
        } else {
          return output + text
        }
        } else if(text === '.') {
          if(/(\.\d*|\D)$/.test(output)) {
          return output;
        } else {
          return output + '.';
        }
        } else if(text === '删除') {
          if(output.length > 1) {
          return output.slice(0, -1) || '0';
        } else {
          return '0'
        }
        } else if(text === '清零') {
          return '0';
        } else if(text === '完成') {
          let strArr = output.split(/(\+|-)/)
          let newStrArr = this.transArray(strArr)
          let total = newStrArr.reduce((sum, cur)=> {
            return sum + parseFloat((cur))
          }, 0.0)
          return total.toString()
        } else {
          return '0'
        }

  }

  layoutOptions: GridLayoutOptions = {
    regularSize: [1, 1],
    onGetRectByIndex: (index: number) => {
      if (index == 0) { // key1是“0”按键对应的index
        return [0, 0, 1, 4]
      } else {
        const adjusted = index - 1;
        return [Math.floor(adjusted / 4) + 1, adjusted % 4, 1, 1]
      }
    }
  }

  getTextAlign = (index: number) => {
    if(index === 0) {
      return TextAlign.End
    } else {
      return TextAlign.Center
    }
  }

  getTextPadding = (index: number) => {
    if(index === 0) {
      return 16
    } else {
      return 0
    }
  }

  getTextBg = (index: number) => {
    if(index === 16) {
      return '#f1c21a'
    } else {
      return '#fff'
    }
  }

  getTextContent = (index: number, item: string) => {
    if(index === 0) {
      return this.totalValue
    } else if(index === 16){
      if(this.totalValue === '' || /^-?\d+\.?\d*$/.test(this.totalValue)) {
        return '完成'
      } else {
        return '='
      }
    } else {
      return item
    }
  }

  showToast(message: string, backgroundColor: string) {
    try {
      promptAction.showToast({
        message,
        shadow: ShadowStyle.OUTER_DEFAULT_SM,
        alignment: Alignment.Top,
        backgroundColor
      })
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`[Keyboard] toast skipped, code=${err.code}, message=${err.message}`);
    }
  }

  build() {
    Grid(undefined, this.layoutOptions) {
      ForEach(this.idx, (item: string, index: number) => {
        GridItem() {
          Text(this.getTextContent(index, item))
            .width('100%')
            .height(40)
            .border({width: 2, color: '#000', style: BorderStyle.Solid, radius: 8})
            .margin({top: 8})
            .fontSize(24)
            .backgroundColor(this.getTextBg(index))
            .textAlign(this.getTextAlign(index))
            .padding({ right: this.getTextPadding(index) })
        }.onClick(() => {
          const text = item;
          if(text === '') {
            console.log("do nothing")
          } else if(text === '完成') {
            // TODO
            // 1. 存到localstorage
            // 2. message提醒
            // this.dialogController.open()
            const finalAmount = this.totalValue;
            if(!this.selectedTag) {
              this.showToast('请先选择标签', '#ffcac8')
              return;
            }
            if(Number(finalAmount || '0') <= 0) {
              this.showToast('请输入金额', '#ffcac8')
              return;
            }
            if(RdbUtils.getStore()) {
              const now = RdbUtils.nowIsoString();
              const record: AccountRecordInput = {
                RECORD_ID: RdbUtils.newRecordId(),
                TAG: this.selectedTag.name,
                TAG_ID: this.selectedTag.id,
                IS_USER_TAG: this.selectedTag.isUserTag ? 1 : 0,
                TYPE: this.selectedTag.category,
                AMOUNT: finalAmount,
                USER_ID: this.userId,
                NOTE: this.noteText || this.smartText,
                CREATE_AT: now,
                UPDATED_AT: now,
                DEVICE_ID: RdbUtils.DEVICE_ID,
                VERSION: 1,
                IS_DELETED: 0,
                SYNC_STATUS: this.userId === 'local' ? 'LOCAL' : 'PENDING'
              };
              RdbUtils.insertAccount(record).then((recordId: number)=> {
                if (this.userId === 'local') {
                  RdbUtils.markSyncStatus(recordId, 'LOCAL').catch(() => {});
                } else if (!this.appToken) {
                  RdbUtils.markSyncStatus(recordId, 'PENDING').catch(() => {});
                } else {
                  BitstripeApiService.createRecord(this.appToken, record).then(() => {
                    RdbUtils.markSyncStatus(recordId, 'SYNCED').catch((err: BusinessError) => {
                      console.error(`[RdbInfo] mark sync status failed, code is ${err.code},message is ${err.message}`);
                    });
                  }).catch((err: BusinessError) => {
                    console.error(`[ServerSync] create record failed, code is ${err.code},message is ${err.message}`);
                    RdbUtils.markSyncStatus(recordId, 'PENDING').catch(() => {});
                  });
                }
                this.showToast(this.userId === 'local' ? '记账成功，登录后可保存到服务端' : '记账成功，已提交服务端保存', '#a6f499')
                this.selectedTag = null;
                this.parsedAmount = '';
                this.smartText = '';
                this.noteText = '';
                this.currentMenu = 'home';
              }).catch((err: BusinessError) => {
                console.log(`[RdbInfo]ExecuteSql failed, code is ${err.code},message is ${err.message}`);
              })
            }
            this.totalValue = '0'
          } else {
            const result =  this.updateOutput(text, '' + this.totalValue)
            if(result.length > 20) return
            this.totalValue = result
          }
        })
      }, (item: string, index: number) => `${index}_${item}`)
    }
    .padding(16)
    .backgroundColor('#9bcabf')
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
    .columnsGap(16)
  }
}
