//
//  Archiver.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/20.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit
/// ファイルを展開する基底クラス
class Archiver : NSObject {
    /// 相応しいArchiverサブクラスのインスタンスを返す
    class func archiverFor(folder:Folder) -> Archiver? {
        let ext:String = folder.originalName?.eExt.lowercaseString ?? ""
        switch ext {
        case "zip":
            return ZipArchiver(folder: folder)
        case "pdf":
            return PdfArchiver(folder: folder)
        case "rar":
            return RarArchiver(folder: folder)
        default:
            return nil
        }
    }
    /// 展開可能かどうかを返す
    class func isArchivable(path:String) -> Bool {
        if (!FileUtil.isFile(path)) {
            return false
        }
        let ext = path.eExt.lowercaseString
        switch ext {
        case "zip":
            return true
        case "pdf":
            return true
        case "rar":
            return true
        default:
            return false
        }
    }
    /**
    展開開始する
    */
    func extract() -> Bool {
        fatalError("not implemented")
    }
    /**
    画像ファイルかどうかを返す
    - parameter fileName: ファイル名
    */
    func isImageFile(fileName:String) -> Bool {
        let ext:String = fileName.eExt.lowercaseString
        return ["png", "jpg", "jpeg", "jpe", "gif"].contains(ext)
    }
}
