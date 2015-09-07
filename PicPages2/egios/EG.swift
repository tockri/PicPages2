//
//  EG
//  PicPages
//
//  Created by 藤田正訓 on 2014/06/29.
//  Copyright (c) 2014年 tockri. All rights reserved.
//

import UIKit

// よく使うメソッドを簡単に呼び出すためのユーティリティクラス
class EG {
    // rootViewControllerを返す
    class func rootViewController() -> UIViewController {
        let app = UIApplication.sharedApplication()
        let window = app.keyWindow
        return window!.rootViewController!
    }
    // アプリケーションのメインWindowを返す
    class func window() -> UIWindow {
        return UIApplication.sharedApplication().windows[0] 
    }
    // AppDelegateインスタンスを返す
    class func appDelegate() -> UIApplicationDelegate {
        return UIApplication.sharedApplication().delegate!
    }
    
    // 現在縦置きかどうか
    class func isPortrait() -> Bool {
        let ori = UIApplication.sharedApplication().statusBarOrientation
        return (ori == UIInterfaceOrientation.Portrait
            || ori == UIInterfaceOrientation.PortraitUpsideDown)
    }
    // 現在横置きか
    class func isLandscape() -> Bool {
        return !isPortrait()
    }
    // iPadか
    class func isForIpad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
    }
    // iPhoneか
    class func isForIphone() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone
    }
    
    // リソース内のパス
    class func resPath(subPath: String) -> String {
        return NSBundle.mainBundle().resourcePath!.eAddPath(subPath)
    }
    
    // ドキュメントのパス
    class func docPath(subPath: String) -> String {
        return NSHomeDirectory().eAddPath("Documents").eAddPath(subPath)
    }
    
    // キャッシュファイルのパス
    class func cachePath(subPath: String) -> String {
        return NSHomeDirectory().eAddPath("Library/Caches").eAddPath(subPath)
    }
    
    // テンポラリファイルのパス
    class func tmpPath(subPath: String) -> String {
        return NSHomeDirectory().eAddPath("tmp").eAddPath(subPath)
    }
    // NSUserDefaultsオブジェクトを返す
    class func configs() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    // 設定値を返す
    class func configValue(key: String) -> AnyObject? {
        let cf = configs()
        return cf.valueForKey(key)
    }
    // 設定値を設定する
    class func setConfigValue(key: String, value: AnyObject?) {
        let cf = configs()
        cf.setValue(value, forKey: key)
    }
    // Bool設定値を返す
    class func configBool(key: String) -> Bool {
        return configValue(key)?.boolValue ?? false
    }
    // Bool設定値を設定する
    class func setConfigBool(key: String, value: Bool) {
        let cf = configs()
        cf.setBool(value, forKey: key)
    }
    // Int設定値を返す
    class func configInt(key: String) -> Int? {
        let i = configValue(key)?.intValue
        return i != nil ? Int(i!) : nil
    }
    // Int設定値を設定する
    class func setConfigInt(key: String, value: Int) {
        let cf = configs()
        cf.setInteger(value, forKey: key)
    }
    // OKボタンだけを持つダイアログを表示する
    class func alert(viewController: UIViewController, title: String, message: String = "", onOK: () -> Void = {}) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: eR("OK"), style: UIAlertActionStyle.Default, handler: {action in onOK()}))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    // OK/Cancelボタンを持つダイアログを表示する
    class func confirm(viewController: UIViewController, title: String, message: String = "", onOK: () -> Void = {}, onCancel: () -> Void = {}) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: eR("OK"), style: UIAlertActionStyle.Default, handler: {action in onOK()}))
        alert.addAction(UIAlertAction(title: eR("Cancel"), style: UIAlertActionStyle.Cancel, handler: {action in onCancel()}))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    // テキスト入力ダイアログを表示する
    class func prompt(viewController: UIViewController, title: String, message: String = "", placeholder: String = "", onOK: (String) -> Void, onCancel: () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        var textField: UITextField? = nil
        alert.addTextFieldWithConfigurationHandler({tf in
            tf.placeholder = placeholder
            textField = tf
        })
        alert.addAction(UIAlertAction(title: eR("OK"), style: UIAlertActionStyle.Default, handler: {action in onOK(textField!.text!)}))
        alert.addAction(UIAlertAction(title: eR("Cancel"), style: UIAlertActionStyle.Cancel, handler: {action in onCancel()}))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
}

// なんでも文字列にする
func eS(anything: Any) -> String {
    return "\(anything)"
}
// NSLocalizedStringを短縮するエイリアス
func eR(key:String) -> String {
    return NSLocalizedString(key, comment:"")
}
