//
//  String.extension.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/06/29.
//  Copyright (c) 2014年 tockri. All rights reserved.
//

import Foundation

extension String {
    // ファイル名を返す
    var eFilename : String {
        get {
            return (self as NSString).lastPathComponent
        }
    }
    // ディレクトリを返す
    var eDirname : String {
        get {
            return (self as NSString).stringByDeletingLastPathComponent
        }
    }
    // ディレクトリと拡張子を除く
    var eBasename : String {
        get {
            return (eFilename as NSString).stringByDeletingPathExtension
        }
    }
    // 拡張子を返す
    var eExt :String {
        get {
            return (self as NSString).pathExtension
        }
    }
    // cStringUsingEncodingのエイリアス
    var eCString :[CChar] {
        get {
            return cStringUsingEncoding(NSUTF8StringEncoding)!
        }
    }
    // Trim
    var eTrim :String {
        get {
            return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }
    // stringByAppendintなんたらのエイリアス
    func eAddPath(path:String) -> String {
        return (self as NSString).stringByAppendingPathComponent(path)
    }
    // substring
    func eSub(from:Int, len:Int) -> String {
        let start = self.startIndex.advancedBy(from)
        let r = Range<String.Index>(start:start, end:start.advancedBy(len))
        return substringWithRange(r)
    }
    
    // 分割する
    func eSplit(delim: String) -> [String] {
        return componentsSeparatedByString(delim)
    }
    // 正規表現マッチ
    func eMatch(pattern: String) -> [String] {
        let options: NSRegularExpressionOptions = [NSRegularExpressionOptions.CaseInsensitive, NSRegularExpressionOptions.DotMatchesLineSeparators]
        let regexp = try! NSRegularExpression(pattern: pattern,
            options: options)
        let match = regexp.firstMatchInString(self,
            options: [],
            range: NSMakeRange(0, self.characters.count))
        var ret : [String] = []
        if (match != nil) {
            for i in 0 ..< match!.numberOfRanges {
                let range = match!.rangeAtIndex(i)
                ret.append((self as NSString).substringWithRange(range))
            }
        }
        return ret;
    }
}