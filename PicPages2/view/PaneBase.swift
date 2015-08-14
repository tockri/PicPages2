//
//  PaneBase.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/12/06.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import UIKit

class PaneBase: UIViewController {
    private var covering: Bool = false

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Logger.debug(self)
    }
    
    /**
    新しいViewControllerをFadeinで重ねて表示する
    :param: identifier StoryboardのIdentifier
    :param: onView 表示するview
    :param: complete Fadein完了時に呼ばれるクロージャ
    :returns: 子ViewControllerを返す
    */
    func showCoverViewController(identifier: String, onView: UIView? = nil, complete:(PaneBase) -> Void = {_ in}) -> PaneBase {
        var cp = storyboard?.instantiateViewControllerWithIdentifier(identifier) as! PaneBase
        addChildViewController(cp)
        cp.view.hidden = true
        (onView ?? view).addSubview(cp.view)
        cp.view.eFitToSuperview()
        cp.view.eFadein(complete: {
            complete(cp)
        })
        cp.covering = true
        return cp
    }
    
    /**
    表示しているViewControllerをFadeoutで非表示にする
    */
    @IBAction func dismissCoveringViewController() {
        if (covering) {
            view.eFadeout(complete: {
                let p = self.parentViewController as? PaneBase
                p?.coveredViewControllerWillDismiss(self)
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            })
        }
    }
    /**
    showCoverViewControllerで表示した子ViewControllerがdismissCoveringViewControllerで
    非表示になった時呼ばれる
    :param: viewController 子ViewController
    */
    func coveredViewControllerWillDismiss(viewController:PaneBase) {
        
    }
    
    /**
    アプリがバックグラウンドに入るとき呼ばれる
    */
    func onEnterBackground() {
        
    }
    
    /**
    アプリがフォアグラウンドに入るとき呼ばれる
    */
    func onEnterForeground() {
        
    }

    /**
    ナビゲーションを戻る
    */
    @IBAction func back() {
        navigationController?.popViewControllerAnimated(true)
    }

}
