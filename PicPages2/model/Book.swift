//
//  Book.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/18.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit
/// 本クラス
class Book : NSObject {
    private let folder:Folder
    
    // MARK: - properties
    var pageCount: Int {
        return folder.pageCount
    }
    
    // MARK: - Constructor
    init(folder:Folder) {
        self.folder = folder
    }
    
    // MARK: - private methods
    
    /**
    画面サイズに合わせてリサイズする
    :param: img 画像
    :returns: リサイズ後画像
    */
    private func resize(img:UIImage) -> UIImage {
        // キャンバスサイズ
        var cvSize = UIScreen.mainScreen().bounds.size
        let imSize = img.size
        if (imSize.width > imSize.height && cvSize.width < cvSize.height) {
            // 横長画像でキャンバスが縦長の場合
            cvSize.width *= 2
        } else if (imSize.width < imSize.height && cvSize.width > cvSize.height) {
            // 縦長画像でキャンバスが横長の場合
            cvSize.height *= 2
        }
        let scale = UIScreen.mainScreen().scale
        cvSize.width *= scale
        cvSize.height *= scale
        let ret = img.eResizeIn(cvSize)
//        let rSize = ret.size
//        println("\(rSize)")
        return ret
    }
    
    

    // MARK: - public methods
    
    // ページ画像を返す
    func pageImageAt(page: Int) -> UIImage? {
        if (1 <= page && page <= folder.pageCount) {
            let realPath = folder.realPath!.eAddPath(String(format: "%05d", page))
            if (FileUtil.exists(realPath)) {
                //Logger.debug("UIImage(\(realPath))")
                let img = UIImage(contentsOfFile: realPath)!
                return img
            } else {
                Logger.warn("file not found!!! : " + realPath)
            }
        }
        return nil
    }
    
    
    /**
    サムネイル画像を返す
    :returns: 画像
    */
    func thumbImage() -> UIImage? {
        let thumbPath = folder.realPath!.eAddPath("thumb")
        if (!FileUtil.exists(thumbPath)) {
            let img = pageImageAt(1)
            if (img == nil) {
                return nil
            }
            let thumb = img?.eResize(CGSize(width: 300, height: 300))
            let data = UIImageJPEGRepresentation(thumb, 0.9)
            data.writeToFile(thumbPath, atomically: false)
            return thumb
        } else {
            return UIImage(contentsOfFile: thumbPath)
        }
    }
    
    
}