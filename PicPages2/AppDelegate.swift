//
//  AppDelegate.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/11/24.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let KEY_PASSCODE = "login.passCode"
    private let KEY_REMEMBER_LOGIN = "remember.login"
    private let KEY_LOGINSTATE = "loginState"
    private var loginState :Bool = false
    
    var window: UIWindow?
    
    // MARK: - private vars
    
    ///現在表示しているPaneBase
    private var topPane:  PaneBase? {
        let navi = EG.rootViewController() as? UINavigationController
        if (navi != nil) {
            return navi!.topViewController as? PaneBase
        }
        return nil
    }
    
    // MARK: - public vars
    
    // パスコードが設定されているかどうか
    var isPasscodeSet: Bool {
        let pass:String = EG.configValue(KEY_PASSCODE) as? String ?? ""
        return (pass != "")
    }
    // ログイン中かどうか
    var isLogined :Bool {
        return loginState
    }
    /// ログイン保存設定
    var rememberLogin: Bool {
        get {
            return EG.configBool(KEY_REMEMBER_LOGIN)
        }
        set {
            EG.setConfigBool(KEY_REMEMBER_LOGIN, value: newValue)
            EG.setConfigBool(KEY_LOGINSTATE, value: isLogined && newValue)
        }
    }
    
    
    // MARK: - private methods

    /**
    テスト用のデータ初期化
    */
    private func testInitialize() {
        // DBコピーを削除
        FileUtil.rm(EG.cachePath("db"))
        // キャッシュを削除
        FileUtil.rm(EG.cachePath("book"))
        // サンプルファイルをコピー
        let files = FileUtil.files(EG.resPath("testdata"))
        for file in files {
            let docPath = EG.docPath(file)
            if (!FileUtil.exists(docPath)) {
                FileUtil.copy(EG.resPath("testdata/" + file), to: docPath)
            }
        }
    }
    
    // MARK: - UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        //testInitialize()
        // Override point for customization after application launch.
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if (!rememberLogin) {
            loginState = false
        }
        topPane?.onEnterBackground()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        loginState = EG.configBool(KEY_LOGINSTATE)
        topPane?.onEnterForeground()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - public methods
    
    class func getInstance() -> AppDelegate {
        return EG.appDelegate() as! AppDelegate
    }
    
    // パスコードを設定する
    func setPassCode(passCode: String) {
        EG.setConfigValue(KEY_PASSCODE, value: passCode)
        loginState = true
    }
    // ログインする
    func tryLogin(passCode: String) -> Bool {
        let pass = EG.configValue(KEY_PASSCODE) as? String?
        if (pass != nil && pass! == passCode) {
            loginState = true
            if (rememberLogin) {
                EG.setConfigBool(KEY_LOGINSTATE, value: true)
            }
        }
        return loginState
    }
    // ログアウトする
    func logout() {
        loginState = false
        EG.setConfigBool(KEY_LOGINSTATE, value: false)
    }
    

}

