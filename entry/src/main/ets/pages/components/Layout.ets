@Component
struct ChildItem {
  @Prop title: string;
  @Prop colorStr: string;
  @Link currentMenu: string;

  getTitle = (name: string) => {
    if(name === 'home') {
      return '今天'
    } else if(name === 'money') {
      return '记账'
    } else {
      return '统计'
    }
  }

  getIcon = (name: string) => {
    return name + '.svg'
  }

  build() {
    Column() {
      Column() {
        Image($rawfile('icons/'+this.getIcon(this.title)))
          .width(24)
          .height(24)
          .fillColor(this.colorStr)
        Text(this.getTitle(this.title))
          .fontSize(12)
          .fontColor(this.colorStr)
          .padding({top: 10})
      }
      .onClick(() => {
          this.currentMenu = this.title
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}


@Component
export struct LayoutComponent {
  @State menus: Array<string> = ['home', 'money'];

  @Link currentMenu: string;


  @Builder homeBuilder() {};
  // 使用父组件@Builder装饰的方法初始化子组件@BuilderParam
  @BuilderParam homeBuilderParam: () => void = this.homeBuilder;

  @Builder countBuilder() {};
  // 使用父组件@Builder装饰的方法初始化子组件@BuilderParam
  @BuilderParam countBuilderParam: () => void = this.countBuilder;

  build() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween }) {
      if(this.currentMenu === 'home') {
        this.homeBuilderParam()
      } else {
        this.countBuilderParam()
      }

      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
        ForEach(this.menus, (item: string) => {
          ChildItem({ title: item, colorStr: item === this.currentMenu ? '#a3c6bf' : '#d7e0e2', currentMenu: $currentMenu })
        }, (item: string) => item)
      }
      .height(68)
      .padding({top: 5, bottom: 5})
      .width('100%')
      .backgroundColor('#f7f8f3')
    }
  }
}
