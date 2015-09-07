//
//  AbstractFolderPaneViewController.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/25.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

/// Folderを表示する画面の基底クラス
class AbstractFolderPane: PaneBase {
    /// 表示するFolderオブジェクト
    private var _folder: Folder!
    var folder: Folder! {
        get {
            return _folder
        }
        set {
            _folder = newValue
            onFolderSet(newValue)
        }
    }

    /**
    Folderが設定されたときに呼ばれる
    - parameter f: フォルダ
    */
    func onFolderSet(f:Folder) {
    }
    
    /**
    ログイン必要なフォルダを表示している時に前の画面に戻る
    */
    override func onEnterBackground() {
        let app = AppDelegate.getInstance()
        if (folder.needsLogin && !app.isLogined) {
            let panes:[AnyObject]! = navigationController?.viewControllers
            if (panes == nil) {
                return
            }
            var dst:UIViewController! = nil
            for var i = panes.count - 1; i >= 0; i-- {
                let pane = panes[i] as? AbstractFolderPane
                if (pane == nil) {
                    break
                } else if (!pane!.folder.needsLogin) {
                    dst = pane
                    break
                }
            }
            if (dst != nil) {
                navigationController?.popToViewController(dst, animated: false)
            }
        }
    }
    
    
    
}
