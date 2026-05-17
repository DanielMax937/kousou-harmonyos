import RdbUtils, { MyTag } from "../../common/rdbUtils/RdbUtils";
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
  @State expandedHistory: boolean = false;
  @State visibleRecordCount: number = 12;

  @State todayIncome: number = 0;
  @State todayCost: number = 0;

  @State recordList: FormatRecordList[] = [];


  @Watch('handleMenuChange') @Link currentMenu: string;
  @Link userId: string;
  @Watch('handleSyncChange') @Link syncRevision: number;

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

  handleMenuChange() {
    if (this.currentMenu === 'home' && RdbUtils.getStore()) {
      this.queryData();
    }
  }

  handleSyncChange() {
    if (this.currentMenu === 'home' && RdbUtils.getStore()) {
      this.queryData();
    }
  }

  currentLocalDateKeys(): string[] {
    const offsets = [0, 8, 16];
    const keys: string[] = [];
    offsets.forEach((offset: number) => {
      const key = new Date(Date.now() + offset * 60 * 60 * 1000).toISOString().slice(0, 10);
      if (!keys.includes(key)) {
        keys.push(key);
      }
    });
    return keys;
  }


  queryData = () => {
    const queryTasks: Promise<Array<MyTag>>[] = this.userId === 'local'
      ? [RdbUtils.queryAll('ACCOUNT', this.userId)]
      : [RdbUtils.queryAll('ACCOUNT', this.userId), RdbUtils.queryAll('ACCOUNT', 'local')];
    Promise.all(queryTasks).then((queryResults)=> {
      const res = queryResults.reduce((all, item) => all.concat(item), []);
      const todayKeys = this.currentLocalDateKeys();

      const homeRecordList: MyRecord[] = [];
      res.forEach((item)=> {
        console.log('RdbInfo', item.toString())
        const target = INIT_TAG.find((tag)=>tag.name === item.tag )
        if (!target) {
          console.warn(`[RdbInfo] skip unknown tag ${item.tag}`);
          return;
        }
        homeRecordList.push({
          createAt: item.createAt,
          amount: item.amount,
          category: item.type,
          note: "",
          tagId: target.id
        })
      })

      const todayRecordList = homeRecordList.reduce((arr, item) => {
        if(todayKeys.some((key: string) => item.createAt.includes(key))){
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
    }).catch((error: Error) => {
      console.error(`[RdbInfo] query home data failed: ${error.message}`);
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
    if(this.showHistory && !this.expandedHistory) {
      // 如果高度足够放下原来的，则不会抖动，否则，会拉长整个页面，然后页面变长，位置会重新计算，会抖动
      return '60%';
    } else if (this.expandedHistory) {
      return '28%';
    } else {
      return '100%';
    }
  }

  sortedRecordList(): FormatRecordList[] {
    return this.recordList.slice().sort((a: FormatRecordList, b: FormatRecordList) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }

  totalRecordCount(): number {
    return this.recordList.reduce((total: number, item: FormatRecordList) => total + item.list.length, 0);
  }

  visibleRecordList(): FormatRecordList[] {
    let remain = this.expandedHistory ? this.visibleRecordCount : 8;
    const result: FormatRecordList[] = [];
    this.sortedRecordList().forEach((day: FormatRecordList) => {
      if (remain <= 0) {
        return;
      }
      const list = day.list.slice(0, remain);
      if (list.length > 0) {
        result.push({ date: day.date, list });
        remain -= list.length;
      }
    });
    return result;
  }

  loadMoreRecords() {
    this.visibleRecordCount += 12;
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
              this.currentMenu = 'money'
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
            if (!this.showHistory) {
              this.expandedHistory = false;
              this.visibleRecordCount = 12;
            }
            // this.queryData();
          })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height(this.calcHeight())

        if(this.showHistory) {
          Row() {
            Text(this.expandedHistory ? '最近账单' : '最近账单预览')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111')
            Text(this.expandedHistory ? '收起' : '展开全部')
              .fontSize(14)
              .fontColor('#2f7468')
              .onClick(() => {
                this.expandedHistory = !this.expandedHistory;
                this.visibleRecordCount = this.expandedHistory ? 24 : 12;
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 8 })
          Scroll() {
            Column(){
              ForEach(this.visibleRecordList(), (item: FormatRecordList, _) => {
                Recent({
                  item: item
                })
              }, (item: FormatRecordList) => item.date)
              if (this.expandedHistory && this.visibleRecordCount < this.totalRecordCount()) {
                Text('加载更多')
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .fontColor('#1f2f2b')
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .backgroundColor('#edf0ec')
                  .border({ radius: 8 })
                  .margin({ top: 10 })
                  .onClick(() => {
                    this.loadMoreRecords();
                  })
              }
              if (this.expandedHistory && this.totalRecordCount() > 0 && this.visibleRecordCount >= this.totalRecordCount()) {
                Text('没有更多了')
                  .fontSize(12)
                  .fontColor('#8d9996')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 4 })
              }
            }
            .justifyContent(FlexAlign.Start)
            .padding({left: 20, right: 20, bottom: 10})
          }
          .height(this.expandedHistory ? 520 : 250)
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
