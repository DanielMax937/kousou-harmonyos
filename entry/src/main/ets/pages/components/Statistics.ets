import RdbUtils, { MyTag } from "../../common/rdbUtils/RdbUtils";
import { BitstripeApiService, ServerStatisticsResult, ServerStatisticsTag } from "../../common/server/BitstripeApiService";

interface LocalTagStat {
  tag: string;
  type: string;
  amount: number;
  count: number;
}

interface DailyStat {
  date: string;
  income: number;
  cost: number;
}

@Component
export struct Statistics {
  @Link userId: string;
  @Link appToken: string;
  @Watch('handleSyncChange') @Link syncRevision: number;

  @State month: string = '';
  @State income: number = 0;
  @State cost: number = 0;
  @State recordCount: number = 0;
  @State tip: string = '暂无统计数据';
  @State tagStats: LocalTagStat[] = [];
  @State activeType: string = 'cost';
  @State chartType: string = 'trend';
  @State dailyStats: DailyStat[] = [];
  @State showMonthPicker: boolean = false;
  @State pickerYear: number = 2026;
  @State aiTips: string[] = [];
  @State aiLoading: boolean = false;

  aboutToAppear() {
    this.month = this.currentMonth();
    this.pickerYear = Number(this.month.slice(0, 4));
    this.loadData();
  }

  handleSyncChange() {
    this.loadData();
  }

  previousMonth() {
    this.shiftMonth(-1);
  }

  nextMonth() {
    if (this.isCurrentOrFutureMonth(this.month)) {
      return;
    }
    this.shiftMonth(1);
  }

  shiftMonth(offset: number) {
    const parts = this.month.split('-');
    const date = new Date(Number(parts[0]), Number(parts[1]) - 1 + offset, 1);
    const month = date.getMonth() + 1;
    this.month = `${date.getFullYear()}-${month < 10 ? '0' + month : month}`;
    this.loadData();
  }

  analyzeWithAi() {
    if (!this.appToken || this.userId === 'local') {
      this.aiTips = ['登录华为账号后可使用 AI 统计建议'];
      return;
    }
    this.aiLoading = true;
    BitstripeApiService.analyzeStatistics(this.appToken, this.month).then((result) => {
      this.aiTips = result.tips;
    }).catch(() => {
      this.aiTips = [this.tip];
    }).finally(() => {
      this.aiLoading = false;
    });
  }

  loadData() {
    if (this.appToken && this.userId !== 'local') {
      BitstripeApiService.getStatistics(this.appToken, this.month).then((result: ServerStatisticsResult) => {
        this.income = Number(result.overview.income);
        this.cost = Number(result.overview.cost);
        this.recordCount = result.overview.recordCount;
        this.tip = result.summary['tip'] ?? '暂无统计建议';
        this.tagStats = result.byTag.map((item: ServerStatisticsTag) => {
          const stat: LocalTagStat = {
            tag: item.tag,
            type: item.type,
            amount: Number(item.amount),
            count: item.count
          };
          return stat;
        });
        this.dailyStats = result.daily.map((item: Record<string, string>) => {
          const stat: DailyStat = {
            date: item['date'] ?? '',
            income: Number(item['income'] ?? '0'),
            cost: Number(item['cost'] ?? '0')
          };
          return stat;
        });
      }).catch(() => {
        this.loadLocalData();
      });
      return;
    }
    this.loadLocalData();
  }

  loadLocalData() {
    const tasks: Promise<Array<MyTag>>[] = this.userId === 'local'
      ? [RdbUtils.queryAll('ACCOUNT', this.userId)]
      : [RdbUtils.queryAll('ACCOUNT', this.userId), RdbUtils.queryAll('ACCOUNT', 'local')];
    Promise.all(tasks).then((results) => {
      const rows = results.reduce((all, item) => all.concat(item), []);
      const tagMap: Record<string, LocalTagStat> = {};
      const dailyMap: Record<string, DailyStat> = {};
      let income = 0;
      let cost = 0;
      let count = 0;
      rows.forEach((item: MyTag) => {
        if (!item.createAt.startsWith(this.month)) {
          return;
        }
        const amount = Number(item.amount);
        count += 1;
        if (item.type === 'income') {
          income += amount;
        } else {
          cost += amount;
        }
        const dayKey = item.createAt.slice(0, 10);
        if (!dailyMap[dayKey]) {
          dailyMap[dayKey] = { date: dayKey, income: 0, cost: 0 };
        }
        if (item.type === 'income') {
          dailyMap[dayKey].income += amount;
        } else {
          dailyMap[dayKey].cost += amount;
        }
        const key = `${item.type}:${item.tag}`;
        if (!tagMap[key]) {
          tagMap[key] = { tag: item.tag, type: item.type, amount: 0, count: 0 };
        }
        tagMap[key].amount += amount;
        tagMap[key].count += 1;
      });
      this.income = income;
      this.cost = cost;
      this.recordCount = count;
      this.tagStats = Object.keys(tagMap).map((key: string) => tagMap[key]).sort((a: LocalTagStat, b: LocalTagStat) => b.amount - a.amount);
      this.dailyStats = Object.keys(dailyMap).map((key: string) => dailyMap[key]).sort((a: DailyStat, b: DailyStat) => a.date.localeCompare(b.date));
      const topCost = this.tagStats.find((item: LocalTagStat) => item.type === 'cost');
      this.tip = topCost ? `本月支出最高分类是${topCost.tag}，累计 ¥${topCost.amount.toFixed(2)}` : '本月暂无支出记录';
    }).catch(() => {
      this.tip = '统计加载失败';
    });
  }

  currentMonth(): string {
    const date = new Date();
    const month = date.getMonth() + 1;
    return `${date.getFullYear()}-${month < 10 ? '0' + month : month}`;
  }

  typeTabBg(type: string): string {
    return this.activeType === type ? '#a1e0cf' : '#edf0ec';
  }

  chartTabBg(type: string): string {
    return this.chartType === type ? '#a1e0cf' : '#edf0ec';
  }

  filteredStats(): LocalTagStat[] {
    return this.tagStats.filter((item: LocalTagStat) => item.type === this.activeType);
  }

  maxFilteredAmount(): number {
    const items = this.filteredStats();
    if (items.length === 0) {
      return 1;
    }
    return Math.max(...items.map((item: LocalTagStat) => item.amount));
  }

  maxDailyAmount(): number {
    if (this.dailyStats.length === 0) {
      return 1;
    }
    return Math.max(1, ...this.dailyStats.map((item: DailyStat) => Math.max(item.income, item.cost)));
  }

  monthOptions(): string[] {
    const values: string[] = [];
    for (let index = 1; index <= 12; index += 1) {
      const month = index < 10 ? '0' + index : `${index}`;
      values.push(`${this.pickerYear}-${month}`);
    }
    return values;
  }

  isCurrentOrFutureMonth(month: string): boolean {
    return month >= this.currentMonth();
  }

  selectMonth(month: string) {
    if (month > this.currentMonth()) {
      return;
    }
    this.month = month;
    this.showMonthPicker = false;
    this.loadData();
  }

  build() {
    Scroll() {
      Column() {
        Text('统计')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ top: 24, bottom: 18 })

        Row() {
          Button('<')
            .width(42)
            .height(36)
            .backgroundColor('#edf0ec')
            .fontColor('#1f2f2b')
            .onClick(() => {
              this.previousMonth();
            })
          Text(this.month)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .onClick(() => {
              this.showMonthPicker = !this.showMonthPicker;
              this.pickerYear = Number(this.month.slice(0, 4));
            })
          Button('>')
            .width(42)
            .height(36)
            .backgroundColor('#edf0ec')
            .fontColor(this.isCurrentOrFutureMonth(this.month) ? '#b8c2bf' : '#1f2f2b')
            .onClick(() => {
              this.nextMonth();
            })
        }
        .width('100%')
        .margin({ bottom: 12 })

        if (this.showMonthPicker) {
          Column() {
            Row() {
              Button('<')
                .width(42)
                .height(34)
                .backgroundColor('#edf0ec')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.pickerYear -= 1;
                })
              Text(`${this.pickerYear} 年`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
              Button('>')
                .width(42)
                .height(34)
                .backgroundColor('#edf0ec')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  if (this.pickerYear < Number(this.currentMonth().slice(0, 4))) {
                    this.pickerYear += 1;
                  }
                })
            }
            .width('100%')
            Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
              ForEach(this.monthOptions(), (item: string) => {
                Text(item.slice(5, 7) + '月')
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .fontColor(item > this.currentMonth() ? '#b8c2bf' : '#1f2f2b')
                  .width('25%')
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor(this.month === item ? '#a1e0cf' : '#fff')
                  .border({ radius: 6 })
                  .onClick(() => {
                    this.selectMonth(item);
                  })
              }, (item: string) => item)
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .margin({ bottom: 12 })
          .backgroundColor('#f2f5f0')
          .border({ radius: 8 })
        }

        Row() {
          Column() {
            Text('本月支出')
              .fontSize(13)
              .fontColor('#66736f')
            Text(`¥${this.cost.toFixed(2)}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          Column() {
            Text('本月收入')
              .fontSize(13)
              .fontColor('#66736f')
            Text(`¥${this.income.toFixed(2)}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2f7468')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        .backgroundColor('#f2f5f0')
        .border({ radius: 8 })

        Text(`结余 ¥${(this.income - this.cost).toFixed(2)} · ${this.recordCount} 笔记录`)
          .fontSize(14)
          .fontColor('#66736f')
          .width('100%')
          .margin({ top: 12, bottom: 18 })

        Text(this.tip)
          .fontSize(14)
          .fontColor('#1f2f2b')
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 14, right: 14 })
          .backgroundColor('#dce7e2')
          .border({ radius: 8 })

        Button(this.aiLoading ? '分析中...' : 'AI 统计建议')
          .height(40)
          .width('100%')
          .margin({ top: 10 })
          .backgroundColor('#f1c21a')
          .fontColor('#222')
          .onClick(() => {
            this.analyzeWithAi();
          })

        ForEach(this.aiTips, (item: string) => {
          Text(item)
            .fontSize(13)
            .fontColor('#1f2f2b')
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .margin({ top: 6 })
            .backgroundColor('#fff')
            .border({ radius: 8, width: 1, color: '#edf0ec' })
        }, (item: string, index: number) => `${index}_${item}`)

        Row() {
          Text('趋势')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .width('32%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.chartTabBg('trend'))
            .border({ radius: 6 })
            .onClick(() => {
              this.chartType = 'trend';
            })
          Text('支出图')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .width('32%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.chartTabBg('cost'))
            .border({ radius: 6 })
            .onClick(() => {
              this.chartType = 'cost';
              this.activeType = 'cost';
            })
          Text('收入图')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .width('32%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.chartTabBg('income'))
            .border({ radius: 6 })
            .onClick(() => {
              this.chartType = 'income';
              this.activeType = 'income';
            })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .margin({ top: 18, bottom: 12 })

        if (this.chartType === 'trend') {
          Column() {
            ForEach(this.dailyStats.slice(-14), (item: DailyStat) => {
              Column() {
                Row() {
                  Text(item.date.slice(5))
                    .fontSize(12)
                    .fontColor('#66736f')
                    .width(48)
                  Row() {}
                    .height(7)
                    .width(`${Math.max(3, Math.floor(item.cost / this.maxDailyAmount() * 100))}%`)
                    .backgroundColor('#f1c21a')
                    .border({ radius: 4 })
                    .layoutWeight(1)
                  Text(`¥${item.cost.toFixed(0)}`)
                    .fontSize(11)
                    .fontColor('#66736f')
                    .width(52)
                    .textAlign(TextAlign.End)
                }
                .width('100%')
                Row() {
                  Text('')
                    .width(48)
                  Row() {}
                    .height(7)
                    .width(`${Math.max(3, Math.floor(item.income / this.maxDailyAmount() * 100))}%`)
                    .backgroundColor('#2f7468')
                    .border({ radius: 4 })
                    .layoutWeight(1)
                  Text(`¥${item.income.toFixed(0)}`)
                    .fontSize(11)
                    .fontColor('#66736f')
                    .width(52)
                    .textAlign(TextAlign.End)
                }
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
            }, (item: DailyStat) => item.date)
            if (this.dailyStats.length === 0) {
              Text('本月暂无趋势数据')
                .fontSize(13)
                .fontColor('#8d9996')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 16, bottom: 16 })
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#f9faf5')
          .border({ radius: 8 })
        } else {
          Column() {
            ForEach(this.filteredStats().slice(0, 8), (item: LocalTagStat) => {
              Row() {
                Text(item.tag)
                  .fontSize(13)
                  .fontColor('#111')
                  .width(64)
                Row() {}
                  .height(12)
                  .width(`${Math.max(8, Math.floor(item.amount / this.maxFilteredAmount() * 100))}%`)
                  .backgroundColor(item.type === 'income' ? '#2f7468' : '#f1c21a')
                  .border({ radius: 6 })
                  .layoutWeight(1)
                Text(`${Math.floor(item.amount / this.maxFilteredAmount() * 100)}%`)
                  .fontSize(11)
                  .fontColor('#66736f')
                  .width(40)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
            }, (item: LocalTagStat) => `${item.type}:${item.tag}:chart`)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#f9faf5')
          .border({ radius: 8 })
        }

        Row() {
          Text('支出')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .width('48%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.typeTabBg('cost'))
            .border({ radius: 6 })
            .onClick(() => {
              this.activeType = 'cost';
            })
          Text('收入')
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .width('48%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.typeTabBg('income'))
            .border({ radius: 6 })
            .onClick(() => {
              this.activeType = 'income';
            })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .margin({ top: 18 })

        Text('分类排行')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .width('100%')
          .margin({ top: 24, bottom: 10 })

        ForEach(this.filteredStats(), (item: LocalTagStat) => {
          Column() {
            Row() {
            Column() {
              Text(item.tag)
                .fontSize(16)
                .fontColor('#111')
              Text(`${item.count} 笔 · ${item.type === 'income' ? '收入' : '支出'}`)
                .fontSize(12)
                .fontColor('#8d9996')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            Text(`¥${item.amount.toFixed(2)}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(item.type === 'income' ? '#2f7468' : '#111')
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            Row() {}
              .width(`${Math.max(8, Math.floor(item.amount / this.maxFilteredAmount() * 100))}%`)
              .height(6)
              .backgroundColor(item.type === 'income' ? '#2f7468' : '#f1c21a')
              .border({ radius: 3 })
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .border({ width: { bottom: 1 }, color: '#edf0ec' })
        }, (item: LocalTagStat) => `${item.type}:${item.tag}`)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .width('100%')
    .height('100%')
  }
}
