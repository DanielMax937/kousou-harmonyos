import RdbUtils from "../../common/rdbUtils/RdbUtils";
import { INIT_TAG, Tag } from "./Money";
import { Recent } from "./Recent";

interface MyRecord {
  createAt: string,
  amount: string,
  category: string,
  note: string,
  tagId:number,
}

export interface  NewRecordItem {
  tagId: number,
  amount: string,
  category: string,
  icon: string,
  name: string,
  createAt: string,
}

type FormatRecordObject =  Record<string, Array<NewRecordItem>>

export interface FormatRecordList {
  date: string,
  list: Array<NewRecordItem>
}

interface MatchTag {icon: string, name: string}

@Component
export struct Home {
  @State showHistory: boolean = false;

  @State todayIncome: number = 0;
  @State todayCost: number = 0;

  @State recordList: FormatRecordList[] = [];


  changeTab?: (key: string) => void;

  aboutToAppear() {
    if(RdbUtils.getStore()) {
      this.queryData();
    } else {
      const checker = setInterval(()=> {
        if(RdbUtils.getStore()) {
          this.queryData();
          clearInterval(checker)
        }
      },100)
    }
  }


  queryData = () => {
    RdbUtils.queryAll('ACCOUNT').then((res)=> {
      const current = new Date();
      const timestamp = current.toISOString();
      const match = timestamp.slice(0, 10);

      const homeRecordList: MyRecord[] = [];
      res.forEach((item)=> {
        console.log('RdbInfo', item.toString())
        const target = INIT_TAG.find((tag)=>tag.name === item.tag )
        homeRecordList.push({
          createAt: item.createAt,
          amount: item.amount,
          category: item.type,
          note: "",
          tagId: target!.id
        })
      })

      const todayRecordList = homeRecordList.reduce((arr, item) => {
        if(item.createAt.includes(match)){
          arr.push(item)
        }
        return arr
      }, [] as Array<MyRecord>)

      const todayTotalIncome = (todayRecordList).reduce((total, item) => {
        if(item.category === 'income') {
          return total + Number(item.amount)
        }
        return total
      }, 0)

      const todayTotalCost = (todayRecordList).reduce((total, item) => {
        if(item.category === 'cost') {
          return total + Number(item.amount)
        }
        return total
      }, 0)

      this.todayIncome = todayTotalIncome;
      this.todayCost = todayTotalCost;

      let formatObj: FormatRecordObject = {}
      // 获取tag内容加入到record中
      homeRecordList.forEach((item) => {
        const tagId = item.tagId;
        const category = item.category;
        const amount = item.amount;
        const createAt = item.createAt;

        let matchedTag: MatchTag = { icon: '', name: '' }
        INIT_TAG.forEach((tag: Tag) => {
          const icon = tag.icon;
          const name = tag.name;
          const id = tag.id;
          if(tagId === id) {
            matchedTag = {icon, name}
          }
        })
        const date = createAt.slice(0, 10);
        const newItem: NewRecordItem  = {
          tagId,
          category,
          amount,
          icon: matchedTag.icon,
          name: matchedTag.name,
          createAt: createAt
        }
        if (formatObj[date]) {
          formatObj[date].unshift(newItem)
        } else {
          formatObj[date] = [newItem]
        }
      })
      // 组合date和新的recordItem列表
      let formatList: FormatRecordList[] = []
      Object.keys(formatObj).forEach((key)=> {
        formatList.push({date: key, list: formatObj[key]})
      })
      this.recordList = formatList;
    })
  }


  calcRotate = () => {
    if(this.showHistory) {
      return 180;
    } else {
      return 0;
    }
  }

  calcHeight = () => {
    if(this.showHistory) {
      // 如果高度足够放下原来的，则不会抖动，否则，会拉长整个页面，然后页面变长，位置会重新计算，会抖动
      return '60%';
    } else {
      return '100%';
    }
  }
  build() {
    Scroll(){
      Column() {
        Column() {
          Column() {
            Text('今日支出')
              .fontColor('#9ecdc1')
              .fontSize(14)
            Text('¥'+ this.todayCost)
              .fontColor('#9ecdc1')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .margin({top: 4, bottom: 4})
              .lineHeight(36)
            Text('收入¥'+this.todayIncome)
              .fontColor('#acacac')
              .fontSize(14)
          }
          .margin({top: 100, bottom: 40})

          Text('记一笔')
            .margin({top: 20, bottom: 20})
            .padding({top: 8, bottom: 8, left: 32, right: 32})
            .backgroundColor('#a1e0cf')
            .border({width: 2, color: '#9acdbc', style: BorderStyle.Solid, radius: 8})
            .fontColor('#333')
            .fontSize(14)
            .onClick(()=> {
              if(this.changeTab) {
                this.changeTab('money')
              }
            })

          Row() {
            Text("展示最近账单")
              .fontColor('#adadad')
              .fontSize(16)
            Image($rawfile('icons/up.svg'))
              .width(28)
              .height(28)
              .fillColor('#adadad')
              .rotate({angle: this.calcRotate()})
              .animation({
                duration: 200,
                curve: Curve.EaseOut,
                iterations: 1,
                playMode: PlayMode.Normal
              })
          }
          .onClick(() => {
            this.showHistory = !this.showHistory;
            // this.queryData();
          })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height(this.calcHeight())

        if(this.showHistory) {
          Scroll() {
            Column(){
              ForEach(this.recordList.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime()), (item: FormatRecordList, _) => {
                Recent({
                  item: item
                })
              }, (item: string) => item)
            }
            .justifyContent(FlexAlign.Start)
            .padding({bottom: 10})
          }
          .height(250)
        }
      }
    }
    .width('100%')
  }
}