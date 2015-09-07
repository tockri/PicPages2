//
//  UIImage.extension.swift
//  PicPages2
//
//  Created by 藤田正訓 on 2015/07/29.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

extension UIImage {
    /**
    高品質リサイズした画像を返す
    - parameter size: サイズ
    - returns: 新しいUIImageインスタンス
    */
    func eResize(size:CGSize) -> UIImage {
        var ret: UIImage? = nil
        autoreleasepool { () -> () in
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
            let context = UIGraphicsGetCurrentContext()
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
            drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
            ret = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
        }
        return ret!
    }
    /**
    指定したサイズに収まるようにリサイズした画像を返す
    - parameter size: サイズ
    - returns: 新しいUIImageインスタンス
    */
    func eResizeIn(size:CGSize) -> UIImage {
        var ss = self.size
        let mag = min(size.height / ss.height, min(size.width / ss.width, 1.0))
        if (mag == 1.0) {
            return self
        } else {
            ss.width *= mag
            ss.height *= mag
            return eResize(ss)
        }
    }
}