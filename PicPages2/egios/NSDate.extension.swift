//
//  NSDate.extension.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/02/04.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import Foundation

extension NSDate {
    /**
    文字列に変換する
    :param: format フォーマット文字列。NSDateFormatter準拠
    :returns: 時刻を表す文字列
    */
    func eFormat(_ format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone(abbreviation: "JST")
        return df.stringFromDate(self)
    }
    
    /**
    文字列からNSDateに変換する
    :param: str 文字列
    :param: format フォーマット文字列。NSDateFormatter準拠
    :returns: 時刻
    */
    class func eFromStr(str:String, format:String = "yyyy-MM-dd HH:mm:ss") -> NSDate? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone(abbreviation: "JST")
        return df.dateFromString(str)
    }
}