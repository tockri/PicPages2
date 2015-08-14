//
//  RarArchiver.swift
//  PicPages2
//
//  Created by 藤田正訓 on 2015/07/29.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import Foundation
/// Rarファイルをページ分解するクラス
class RarArchiver: Archiver {
    private let folder:Folder
    init(folder:Folder) {
        self.folder = folder
    }
    
    /**
    アーカイブを展開する
    */
    override func extract() -> Bool {
        var err:NSError? = nil
        let filePath = folder.realPath!.eAddPath(folder.originalName!)
        let ur = Unrar4iOS()
        ur.unrarOpenFile(filePath)
        var result = false
        let encodings = [NSShiftJISStringEncoding, NSUTF8StringEncoding, NSJapaneseEUCStringEncoding]
        for enc in encodings {
            ur.encoding = enc
            let tree = inspect(ur)
            if (tree != nil && tree!.count > 0) {
                makeup(tree!, ur: ur)
                // 成功したらrarファイルだけ削除する
                FileUtil.rm(filePath)
                result = true
                break
            }
        }
        ur.unrarCloseFile()
        return result
    }
    /**
    アーカイブのリストを取得してディレクトリ構成を作る
    :param: ur Unrar4iOS
    :returns: ディレクトリ→ファイル名のツリー
    */
    private func inspect(ur:Unrar4iOS) -> [String:[String]]? {
        let files = ur.unrarListFiles()
        if (files == nil) {
            Logger.warn(ur, message: "rar展開エラー")
            return nil
        }
        var tree = [String:[String]]()
        for file in files {
            let fileName = file as? String
            if (fileName != nil && isImageFile(fileName!)) {
                let dir = fileName!.eDirname
                if (tree[dir] == nil) {
                    tree[dir] = []
                }
                tree[dir]!.append(fileName!)
            }
        }
        for dir in tree.keys {
            sort(&tree[dir]!)
        }
        
        Logger.debug(tree, message: "extracting")
        return tree
    }

    /**
    リストを元に実際に展開する
    :param: tree ディレクトリ→ファイル名のツリー
    :param: ur   Unrar4iOS
    */
    private func makeup(tree:[String:[String]], ur:Unrar4iOS) {
        let dirs = tree.keys.array
        if (dirs.count == 1) {
            makeupBook(folder, dir: dirs[0], files: tree[dirs[0]]!, ur: ur)
        } else {
            folder.isBook = false
            folder.name = dirs[0].eDirname
            folder.save()
            for dir in dirs {
                let cf = folder.createChild(dir.eBasename)
                cf.isMovable = false
                makeupBook(cf, dir: dir, files:tree[dir]!, ur:ur)
            }
        }
    }
    /**
    フォルダ1つ分の処理
    :param: f     フォルダ
    :param: dir   ディレクトリ名
    :param: files ファイル名リスト
    :param: ur    Unrar4iOS
    */
    private func makeupBook(f:Folder, dir:String, files:[String], ur:Unrar4iOS) {
        f.isBook = true
        let n:String = dir.eBasename.eTrim
        if (n != "") {
            f.name = n
        }
        var page:Int = 1
        for fn in files {
            autoreleasepool({ () -> () in
                let dstPath = folder.realPath!.eAddPath(String(format: "%05d", page))
                var err:NSError? = nil
                let data:NSData = ur.extractStream(fn)
                if (FileUtil.exists(dstPath)) {
                    FileUtil.rm(dstPath)
                }
                data.writeToFile(dstPath, atomically: true)
                page++
            })
        }
        f.pageCount = page - 1
        f.cacheCompleted = true
        f.save()
    }
}
