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
    class func debug(_ body: AnyObject! = "",
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
    class func info(_ body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
        self.log(body, message:message, function:function, file:file, line:line, prefix: "INFO")
    }

    // 警告用ログ
    class func warn(_ body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
        self.log(body, message:message, function:function, file:file, line:line, prefix: "WARN")
    }
    // エラーログ
    class func error(_ body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__)
    {
            self.log(body, message:message, function:function, file:file, line:line, prefix: "ERROR")
    }
    
    private class func log(_ body: AnyObject! = "",
        message: String = "",
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__,
        prefix: String = "")
    {
        var fn = file.eFilename
        println("[\(prefix)]\(message)(\(function) \(fn):\(line)) \n\(body)")
    }
}
