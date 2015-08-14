//
//  FileUtil.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/06/29.
//  Copyright (c) 2014年 tockri. All rights reserved.
//
import Foundation

class FileUtil: NSObject {
    
    private class var fm : NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    /// treeの内部メソッド
    private class func treeInner(path:String, includeDir:Bool, prefix:String, inout ret:[String]) {
        let dir = path.eAddPath(prefix)
        for fn in files(dir) {
            let filePath = dir.eAddPath(fn)
            let retPath = prefix.eAddPath(fn)
            if (isDir(filePath)) {
                if (includeDir) {
                    ret.append(retPath)
                }
                treeInner(path, includeDir: includeDir, prefix: retPath, ret: &ret)
            } else {
                ret.append(retPath)
            }
        }
    }
    
    /// ディレクトリ内の再帰的な一覧を返す
    class func tree(path:String, includeDir:Bool = false) -> [String] {
        var ret = [String]()
        treeInner(path, includeDir: includeDir, prefix: "", ret: &ret)
        return ret
    }
    
    
    
    /// ディレクトリのファイル一覧を返す
    class func files(path: String) -> [String] {
        var err : NSError?
        var cont = fm.contentsOfDirectoryAtPath(path, error: &err)
        var ret :[String] = []
        if (err == nil) {
            for c in cont! {
                ret.append(c as! String)
            }
        } else {
            Logger.warn(err)
        }
        return ret
    }
    
    /// ディレクトリかどうかを返す
    class func isDir(path:String) -> Bool {
        return fileType(path) == NSFileTypeDirectory
    }
    /// 通常ファイルかどうかを返す
    class func isFile(path:String) -> Bool {
        return fileType(path) == NSFileTypeRegular
    }
    
    /// ファイルタイプを返す
    class func fileType(path:String) -> String? {
        var err: NSError?
        let attrs:NSDictionary? = fm.attributesOfItemAtPath(path, error: &err)
        if (err == nil) {
            return attrs?.fileType()
        } else {
            Logger.warn(err, message: path)
            return nil
        }
        
    }
    
    // ファイルの存在チェック
    class func exists(path: String) -> Bool {
        return fm.fileExistsAtPath(path)
    }
    
    // ファイルまたはディレクトリ削除
    class func rm(path : String) -> Bool {
        var err : NSError?
        let result = fm.removeItemAtPath(path, error: &err)
        if (!result) {
            Logger.warn(err)
        } else {
            Logger.debug("rm : " + path)
        }
        return result
    }
    
    // ディレクトリ作成
    class func mkdir(path : String) -> Bool {
        if (self.exists(path)) {
            return true
        }
        var err : NSError?
        let result = fm.createDirectoryAtPath(path,
            withIntermediateDirectories:true,
            attributes:nil,
            error:&err)
        if (!result) {
            Logger.warn(err)
        } else {
            Logger.debug("mkdir : " + path)
        }
        return result
    }
    
    /// ファイルを生成する
    class func createFile(path: String) -> NSFileHandle? {
        if (fm.createFileAtPath(path, contents: nil, attributes: nil)) {
            let h = NSFileHandle(forWritingAtPath: path)
            return h
        } else {
            Logger.warn(path, message: "createFileAtPath failed")
            return nil
        }
    }
    
    /**
    ファイル移動
    :param: src 移動元
    :param: dst 移動先
    
    :returns: 移動成功したらtrue
    */
    class func mv(src : String, to dst : String) -> Bool {
        var err: NSError?
        var isDir: ObjCBool = ObjCBool(false)
        var dstPath = dst
        if (fm.fileExistsAtPath(dst, isDirectory:&isDir)) {
            if (isDir.boolValue == true) {
                dstPath = dst.eAddPath(src.eFilename)
            } else {
                // ファイルが存在する場合削除する
                if (!fm.removeItemAtPath(dst, error:&err)) {
                    Logger.warn(err)
                    return false
                }
            }
        }
        // 親ディレクトリを作成
        var dir = dstPath.eDirname
        if (!self.mkdir(dir)) {
            return false
        }
        // コピー
        if (!fm.moveItemAtPath(src, toPath: dstPath, error: &err)) {
            Logger.warn(err)
            return false
        } else {
            Logger.debug("moved : " + src + " to " + dstPath)
        }
        return true
    }
    
    /**
    ファイルコピー
    
    :param: src 移動元
    :param: dst 移動先
    
    :returns: 移動成功したらtrue
    */
    class func copy(src : String, to dst : String) -> Bool {
        var err : NSError?
        var isDir : ObjCBool = ObjCBool(false)
        var dstPath = dst
        if (fm.fileExistsAtPath(dst, isDirectory:&isDir)) {
            if (isDir.boolValue == true) {
                dstPath = dst.eAddPath(src.eFilename)
            } else {
                // ファイルが存在する場合削除する
                if (!fm.removeItemAtPath(dst, error:&err)) {
                    Logger.warn(err)
                    return false
                }
            }
        }
        // 親ディレクトリを作成
        var dir = dstPath.eDirname
        if (!self.mkdir(dir)) {
            return false
        }
        // コピー
        if (!fm.copyItemAtPath(src, toPath:dstPath, error:&err)) {
            Logger.warn(err)
            return false
        } else {
            Logger.debug("copied : " + src + " to " + dstPath)
        }
        return true
    }
    
    
}
