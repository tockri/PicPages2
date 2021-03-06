//
//  ZipArchiver.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/20.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import Foundation
/// Zipファイルをページ分解するクラス
class ZipArchiver: Archiver {
    private let folder:Folder
    init(folder:Folder) {
        self.folder = folder
    }
    /**
    アーカイブを展開する
    */
    override func extract() -> Bool {
        let filePath = folder.realPath!.eAddPath(folder.originalName!)
        let encodings = [NSShiftJISStringEncoding, NSUTF8StringEncoding, NSJapaneseEUCStringEncoding]
        for enc in encodings {
            let options:[String:AnyObject] = [
                ZZOpenOptionsEncodingKey:enc
            ]
            do {
                let za = try ZZArchive(URL: NSURL(fileURLWithPath: filePath), options: options)
                let tree = inspect(za)
                if (tree != nil && tree!.count > 0) {
                    makeup(tree!)
                    // 成功したらzipファイルだけ削除する
                    FileUtil.rm(filePath)
                    return true
                }
            } catch let err as NSError {
                Logger.warn(err, message: "zip展開エラー")
                return false
            }
        }
        return false
    }
    
    /**
    アーカイブを検査する
    - returns: ディレクトリ構成
    */
    private func inspect(za:ZZArchive) -> [String:[String:ZZArchiveEntry]]? {
        let entries = za.entries
        var tree = [String:[String:ZZArchiveEntry]]()
        for e in entries {
            let ze = e as! ZZArchiveEntry
            let fn = ze.fileName
            if (fn == nil) {
                // fileNameが取得できない→エンコーディングエラー
                Logger.debug(ze.debugDescription, message: "fileNameがnil→エンコーディングの問題？")
                return nil
            }
            if (fn != nil && isImageFile(fn)) {
                let dir = fn.eDirname
                if (tree[dir] == nil) {
                    tree[dir] = [:]
                }
                tree[dir]![fn] = ze
            }
        }
        Logger.debug(tree, message: "extracting")
        return tree
    }
    
    /**
    Folderをセットする
    - parameter tree: アーカイブの中身
    */
    private func makeup(tree:[String:[String:ZZArchiveEntry]]) {
        let dirs = Array(tree.keys)
        if (dirs.count == 1) {
            makeupBook(folder, dir: dirs[0], entries: tree[dirs[0]]!)
        } else {
            folder.isBook = false
            folder.name = dirs[0].eDirname
            folder.save()
            for dir in dirs {
                let cf = folder.createChild(dir.eBasename)
                cf.isMovable = false
                makeupBook(cf, dir: dir, entries: tree[dir]!)
            }
        }
    }
    
    /**
    Folder1つ分の処理
    - parameter folder:  フォルダ
    - parameter dir:     フォルダ名
    - parameter entries: zip内容
    */
    private func makeupBook(f:Folder, dir:String, entries:[String:ZZArchiveEntry]) {
        f.isBook = true
        let n:String = dir.eBasename.eTrim
        if (n != "") {
            f.name = n
        }
        var page:Int = 1
        var fns = Array(entries.keys)
        fns.sortInPlace()
        for fn in fns {
            autoreleasepool({ () -> () in
                let e = entries[fn]!
                let dstPath = folder.realPath!.eAddPath(String(format: "%05d", page))
                do {
                    let data:NSData = try e.newData()
                    if (FileUtil.exists(dstPath)) {
                        FileUtil.rm(dstPath)
                    }
                    data.writeToFile(dstPath, atomically: true)
                    page++
                } catch let err as NSError {
                    Logger.warn(err, message: "ZIP Entryの保存でエラー")
                }
            })
        }
        f.pageCount = page - 1
        f.cacheCompleted = true
        f.save()
    }
}
