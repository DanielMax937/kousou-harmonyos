import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { BitstripeApiService, ServerGoal, ServerGoalAnalysis, ServerGoalPayload } from "../../common/server/BitstripeApiService";

@Component
export struct Wishlist {
  @Link userId: string;
  @Link appToken: string;

  @State goals: ServerGoal[] = [];
  @State goalType: string = 'saving';
  @State title: string = '';
  @State targetAmount: string = '';
  @State monthlyIncome: string = '';
  @State description: string = '';
  @State loading: boolean = false;
  @State editingGoalId: string = '';
  @State analysisMap: Record<string, ServerGoalAnalysis> = {};
  @State streamingGoalId: string = '';
  @State streamedAnalysisMap: Record<string, string> = {};

  aboutToAppear() {
    this.loadGoals();
  }

  loadGoals() {
    if (!this.appToken || this.userId === 'local') {
      return;
    }
    BitstripeApiService.getGoals(this.appToken).then((goals: ServerGoal[]) => {
      this.goals = goals;
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
      console.warn(`[Wishlist] toast skipped, code=${err.code}, message=${err.message}`);
    }
  }

  saveGoal() {
    if (!this.appToken || this.userId === 'local') {
      this.showToast('请先登录华为账号', '#ffcac8');
      return;
    }
    if (!this.title || Number(this.targetAmount || '0') <= 0) {
      this.showToast('请填写目标和金额', '#ffcac8');
      return;
    }
    this.loading = true;
    const payload: ServerGoalPayload = {
      goalId: this.editingGoalId || `goal_${Date.now()}`,
      type: this.goalType,
      title: this.title,
      targetAmount: this.targetAmount,
      currentAmount: '0',
      monthlyIncome: this.monthlyIncome || '0',
      description: this.description
    };
    const request = this.editingGoalId
      ? BitstripeApiService.updateGoal(this.appToken, this.editingGoalId, payload)
      : BitstripeApiService.saveGoal(this.appToken, payload);
    request.then((goal: ServerGoal) => {
      const index = this.goals.findIndex((item: ServerGoal) => item.goalId === goal.goalId);
      if (index >= 0) {
        this.goals[index] = goal;
      } else {
        this.goals.unshift(goal);
      }
      this.editingGoalId = '';
      this.title = '';
      this.targetAmount = '';
      this.monthlyIncome = '';
      this.description = '';
      this.showToast('心愿目标已保存', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`保存失败 ${error.message ?? ''}`, '#ffcac8');
    }).finally(() => {
      this.loading = false;
    });
  }

  editGoal(goal: ServerGoal) {
    this.editingGoalId = goal.goalId;
    this.goalType = goal.type;
    this.title = goal.title;
    this.targetAmount = goal.targetAmount;
    this.monthlyIncome = goal.monthlyIncome;
    this.description = goal.description;
  }

  abandonGoal(goal: ServerGoal) {
    if (!this.appToken) {
      return;
    }
    BitstripeApiService.deleteGoal(this.appToken, goal.goalId).then(() => {
      this.goals = this.goals.filter((item: ServerGoal) => item.goalId !== goal.goalId);
      this.showToast('心愿计划已放弃', '#a6f499');
    }).catch((error: BusinessError) => {
      this.showToast(`操作失败 ${error.message ?? ''}`, '#ffcac8');
    });
  }

  analyzeGoal(goal: ServerGoal) {
    if (!this.appToken) {
      return;
    }
    this.streamingGoalId = goal.goalId;
    this.streamedAnalysisMap[goal.goalId] = '';
    BitstripeApiService.analyzeGoalStream(this.appToken, goal.goalId, (delta: string) => {
      this.streamedAnalysisMap[goal.goalId] = (this.streamedAnalysisMap[goal.goalId] || '') + delta;
    }).then((analysis: ServerGoalAnalysis) => {
      this.analysisMap[goal.goalId] = analysis;
      if (!this.streamedAnalysisMap[goal.goalId]) {
        this.streamedAnalysisMap[goal.goalId] = analysis.rawOutput || analysis.suggestions.join('\n');
      }
      this.showToast('AI 分析已生成', '#a6f499');
    }).catch((error: BusinessError) => {
      BitstripeApiService.analyzeGoal(this.appToken, goal.goalId).then((analysis: ServerGoalAnalysis) => {
        this.analysisMap[goal.goalId] = analysis;
        this.streamedAnalysisMap[goal.goalId] = analysis.rawOutput || analysis.suggestions.join('\n');
        this.showToast('AI 分析已生成', '#a6f499');
      }).catch((fallbackError: BusinessError) => {
        this.showToast(`分析失败 ${fallbackError.message ?? error.message ?? ''}`, '#ffcac8');
      });
    }).finally(() => {
      this.streamingGoalId = '';
    });
  }

  typeLabel(type: string): string {
    if (type === 'travel') {
      return '旅行';
    }
    if (type === 'shopping') {
      return '购物';
    }
    return '储蓄';
  }

  selectedTypeColor(type: string): string {
    return this.goalType === type ? '#a1e0cf' : '#edf0ec';
  }

  progressPercent(goal: ServerGoal): number {
    const target = Number(goal.targetAmount || '0');
    const current = Number(goal.currentAmount || '0');
    if (target <= 0) {
      return 0;
    }
    return Math.max(0, Math.min(100, Math.floor(current / target * 100)));
  }

  build() {
    Scroll() {
      Column() {
        Text('心愿')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ top: 24, bottom: 18 })

        if (!this.appToken || this.userId === 'local') {
          Text('登录华为账号后可创建心愿目标和储蓄计划')
            .fontSize(15)
            .fontColor('#66736f')
            .width('100%')
            .padding({ top: 14, bottom: 14, left: 16, right: 16 })
            .backgroundColor('#f2f5f0')
            .border({ radius: 8 })
        } else {
          Column() {
            Row() {
              ForEach(['saving', 'shopping', 'travel'], (item: string) => {
                Text(this.typeLabel(item))
                  .fontSize(14)
                  .fontColor('#1f2f2b')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 8, bottom: 8 })
                  .width('32%')
                  .backgroundColor(this.selectedTypeColor(item))
                  .border({ radius: 6 })
                  .onClick(() => {
                    this.goalType = item;
                  })
              }, (item: string) => item)
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')

            TextInput({ placeholder: '目标名称', text: this.title })
              .height(42)
              .fontSize(14)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.title = value;
              })
            TextInput({ placeholder: '目标金额', text: this.targetAmount })
              .height(42)
              .fontSize(14)
              .type(InputType.Number)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.targetAmount = value;
              })
            TextInput({ placeholder: '月收入，用于估算计划', text: this.monthlyIncome })
              .height(42)
              .fontSize(14)
              .type(InputType.Number)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.monthlyIncome = value;
              })
            TextInput({ placeholder: '备注', text: this.description })
              .height(42)
              .fontSize(14)
              .backgroundColor('#fff')
              .border({ radius: 8 })
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.description = value;
              })
            Button(this.loading ? '保存中...' : (this.editingGoalId ? '更新计划' : '生成计划'))
              .height(42)
              .width('100%')
              .backgroundColor('#f1c21a')
              .fontColor('#222')
              .fontSize(15)
              .margin({ top: 12 })
              .onClick(() => {
                this.saveGoal();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor('#f2f5f0')
          .border({ radius: 8 })
        }

        ForEach(this.goals, (goal: ServerGoal) => {
          Column() {
            Row() {
              Text(goal.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111')
              Text(this.typeLabel(goal.type))
                .fontSize(12)
                .fontColor('#2f7468')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('#dce7e2')
                .border({ radius: 6 })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            Text(`目标 ¥${goal.targetAmount} · 每日存 ¥${goal.dailySavings}`)
              .fontSize(14)
              .fontColor('#66736f')
              .width('100%')
              .margin({ top: 8 })
            Text(goal.planText)
              .fontSize(14)
              .fontColor('#1f2f2b')
              .width('100%')
              .margin({ top: 8 })
            Text(`进度 ${this.progressPercent(goal)}% · 预计 ${goal.timeToGoalDays} 天`)
              .fontSize(13)
              .fontColor('#66736f')
              .width('100%')
              .margin({ top: 8 })
            Row() {}
              .width(`${Math.max(6, this.progressPercent(goal))}%`)
              .height(6)
              .backgroundColor('#f1c21a')
              .border({ radius: 3 })
              .margin({ top: 8 })
            Row() {
              Button('调整')
                .height(34)
                .layoutWeight(1)
                .backgroundColor('#edf0ec')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  this.editGoal(goal);
                })
              Button(this.streamingGoalId === goal.goalId ? '分析中...' : 'AI 分析')
                .height(34)
                .layoutWeight(1)
                .margin({ left: 8 })
                .backgroundColor('#a1e0cf')
                .fontColor('#1f2f2b')
                .onClick(() => {
                  if (this.streamingGoalId !== goal.goalId) {
                    this.analyzeGoal(goal);
                  }
                })
              Button('放弃')
                .height(34)
                .layoutWeight(1)
                .margin({ left: 8 })
                .backgroundColor('#fbe5e5')
                .fontColor('#8a1f1f')
                .onClick(() => {
                  this.abandonGoal(goal);
                })
            }
            .width('100%')
            .margin({ top: 10 })
            if (this.analysisMap[goal.goalId]) {
              ForEach(this.analysisMap[goal.goalId].suggestions, (item: string) => {
                Text(item)
                  .fontSize(13)
                  .fontColor('#1f2f2b')
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
              }, (item: string, index: number) => `${goal.goalId}_${index}_${item}`)
            }
            if (this.streamedAnalysisMap[goal.goalId]) {
              Text(this.streamedAnalysisMap[goal.goalId])
                .fontSize(13)
                .fontColor('#1f2f2b')
                .width('100%')
                .padding({ top: 8, bottom: 8, left: 10, right: 10 })
                .margin({ top: 8 })
                .backgroundColor('#f9faf5')
                .border({ radius: 8, width: 1, color: '#edf0ec' })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 14, bottom: 14, left: 14, right: 14 })
          .margin({ top: 12 })
          .backgroundColor('#fff')
          .border({ radius: 8, width: 1, color: '#edf0ec' })
        }, (goal: ServerGoal) => goal.goalId)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 24 })
    }
    .width('100%')
    .height('100%')
  }
}
