import router from '@ohos.router';
import { authentication } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';


PersistentStorage.persistProp('token', '')

@Entry
@Component
struct Index {
  @State message: string = '这是登录页';
  private title: string = "手机号登录"
  private backColor: ResourceColor = "#DC143C"
  @StorageLink('token') token: string = ''

  onPageShow() {
    // if (this.token.length>0 && this.token !== "undefined"){
    //   console.log('登录页 onPageShow token有值 说明之前 有登录过 直接跳转到首页' + this.token)
    //   this.goToHome()
    // }else {
    //   console.log('登录页 onPageShow token没值 说明之前 没登录过')
    // }
  }
  build() {
    Stack(){
      Text(this.message + this.token)
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .margin({
          top:200
        })
      Button()
        .type(ButtonType.Capsule)
        .width('100%')
        .height('50')
        .backgroundColor(this.backColor)
        .border({
          color:'#CCCCCC',
          width:1
        })
        .margin({
          top:500
        })

      Row(){

        Text(this.title)
          .fontSize(18)
          .fontColor('#333333')

        Text('（上次登录）')
          .fontSize(14)
          .fontColor('#C0C0C0')

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() =>{
        this.mobilePhoneLoginClick()
      })
      .margin({
        top:500
      })
      //.backgroundColor('#32CD32')
    }
    .width('90%')
    .height('50')
    //.backgroundColor('#00BFFF')

  }
  mobilePhoneLoginClick(){
    let loginRequest: authentication.LoginWithHuaweiIDRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
    // 当用户未登录华为帐号时，是否强制拉起华为帐号登录界面
    loginRequest.forceLogin = true;
    // 用于防跨站点请求伪造，推荐采用如下方式给state赋值
    loginRequest.state = '12312';

    // 执行登录请求
    try {
      console.log("aaa 123")
      let controller: authentication.AuthenticationController = new authentication.AuthenticationController(getContext(this));
      controller.executeRequest(loginRequest).then((data: authentication.AuthenticationResponse) => {
        let loginWithHuaweiIDResponse = data as authentication.LoginWithHuaweiIDResponse;
        let state: string = loginWithHuaweiIDResponse.state!;
        let loginWithHuaweiIDCredential: authentication.LoginWithHuaweiIDCredential = loginWithHuaweiIDResponse.data!;
        let code: string = loginWithHuaweiIDCredential.authorizationCode!;
        let idToken: string = loginWithHuaweiIDCredential.idToken!;
        let openID: string = loginWithHuaweiIDCredential.openID;
        let unionID: string = loginWithHuaweiIDCredential.unionID;
        console.log("aaa" + ' openID:' + openID + ' unionID:' + unionID);
        // 获取code后需要将code传给应用服务器，调用华为帐号服务器接口换取Access Token，然后再获取用户其他信息。

      }).catch((err: BusinessError) => {
        console.log("aa" + JSON.stringify(err))
      })
    } catch (e) {
    }

  }


  loginSuccess(){
    let token = 'abc123456'
    console.info('登录成功 存本地的 token：' + token)
    AppStorage.setOrCreate('token',token)
    this.goToHome()
  }

  goToHome(){
    console.info('跳转到 首页')
    router.pushUrl({ url: 'pages/Launch' })
  }
}