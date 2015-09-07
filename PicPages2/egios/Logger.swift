//
//  Logger.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/16.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

class Logger {
    // デバッグ用ログ
    class func debug(body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
        #if DEBUG
            self.log(body, message:message, function:function, file:file, line:line, prefix: "DEBUG")
        #endif
    }
    // 情報用ログ
    class func info(body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
        self.log(body, message:message, function:function, file:file, line:line, prefix: "INFO")
    }

    // 警告用ログ
    class func warn(body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
        self.log(body, message:message, function:function, file:file, line:line, prefix: "WARN")
    }
    // エラーログ
    class func error(body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
            self.log(body, message:message, function:function, file:file, line:line, prefix: "ERROR")
    }
    
    private class func log(body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__,
        prefix: String = "")
    {
        let fn = file.eFilename
        print("[\(prefix)]\(message)(\(function) \(fn):\(line)) \n\(body)", terminator: "")
    }
}
