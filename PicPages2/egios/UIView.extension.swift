//
//  UIView.extension.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/15.
//  Copyright (c) 2015年 tkr. All rights reserved.

import UIKit

extension UIView {
    // 左
    var eLeft: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            eMove(x: newValue, y: eTop)
        }
    }
    // 右
    var eRight: CGFloat {
        get {
            return eLeft + eWidth
        }
        set {
            eResize(width: newValue - eLeft, height: eHeight)
        }
    }
    // 上
    var eTop: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            eMove(x: eLeft, y: newValue)
        }
    }
    // 下
    var eBottom: CGFloat {
        get {
            return eTop + eHeight
        }
        set {
            eResize(width: eWidth, height: newValue - eTop)
        }
    }
    //　幅
    var eWidth: CGFloat {
        get {
            return self.frame.width
        }
        set {
            eResize(width: newValue, height: eHeight)
        }
    }
    // 高さ
    var eHeight: CGFloat {
        get {
            return self.frame.height
        }
        set {
            eResize(width: eWidth, height: newValue)
        }
    }
    // サイズ変更
    func eResize(size: CGSize) {
        eResize(width: size.width, height: size.height)
    }
    // サイズ変更
    func eResize(width width: CGFloat, height: CGFloat) {
        let o = self.frame.origin
        self.frame = CGRect(x: o.x, y: o.y, width: width, height: height)
    }
    // 移動
    func eMove(x x: CGFloat, y: CGFloat) {
        let s = self.frame.size
        self.frame = CGRect(x: x, y: y, width: s.width, height: s.height)
    }
    // フェードイン
    func eFadein(complete:() -> Void = {}) {
        if (hidden) {
            alpha = 0
            hidden = false
            UIView.animateWithDuration(0.3, animations:{
                self.alpha = 1
                }, completion: {finished in
                    complete()
            })
        }
    }
    // フェードアウト
    func eFadeout(complete:() -> Void = {}) {
        if (!hidden) {
            alpha = 1
            UIView.animateWithDuration(0.3, animations: {
                self.alpha = 0
                }, completion: {finished in
                    self.hidden = true
                    self.alpha = 1
                    complete()
            })
        }
    }
    // 親のサイズに合わせる
    func eFitToSuperview() {
        let sv = superview
        if (sv != nil) {
            let size = sv!.frame.size
            frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }
    // 角丸にする
    func eCornerRadius(r: CGFloat) {
        layer.cornerRadius = r
        clipsToBounds = true
    }
    // 縦センターにする
    func eVCenter() {
        let c = NSLayoutConstraint(item: self,
            attribute: .CenterY,
            relatedBy: .Equal,
            toItem: self.superview,
            attribute: .CenterY,
            multiplier: 1,
            constant: 0)
        superview?.addConstraint(c)
    }
    // 横センターにする
    func eHCenter() {
        let c = NSLayoutConstraint(item: self,
            attribute: .CenterX,
            relatedBy: .Equal,
            toItem: self.superview,
            attribute: .CenterX,
            multiplier: 1,
            constant: 0)
        superview?.addConstraint(c)
    }
    
}
