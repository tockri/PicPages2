//
//  UploaderConnection.swift
//  PicPages2
//
//  Created by 藤田正訓 on 2015/08/08.
//  Copyright (c) 2015年 sat. All rights reserved.
//

import UIKit


/// Uploaderの実装
class UploaderConnection: HTTPConnection, MultipartFormDataParserDelegate {
    
    private var parser: MultipartFormDataParser!
    private var dstHandle: NSFileHandle!
    
    
    // MARK: - HTTPConnection override
    
    /**
    /uploadを処理可能にする
    - parameter method: HTTPメソッド
    - parameter path:   パス
    - returns: 処理可能
    */
    override func supportsMethod(method: String!, atPath path: String!) -> Bool {
        if (path == "/upload" && method == "POST") {
            return true
        }
        return super.supportsMethod(method, atPath: path)
    }
    
    /**
    リクエストのBodyを受け取る
    - parameter method: HTTPメソッド
    - parameter path:   パス
    - returns: Bodyを受け取る
    */
    override func expectsRequestBodyFromMethod(method: String!, atPath path: String!) -> Bool {
        if (path == "/upload" && method == "POST") {
            return true
        }
        return super.expectsRequestBodyFromMethod(method, atPath: path)
    }
    
    /**
    レスポンスを返す
    - parameter method: HTTPメソッド
    - parameter path:   パス
    - returns: レスポンス
    */
    override func httpResponseForMethod(method: String!, URI path: String!) -> protocol<NSObjectProtocol, HTTPResponse>! {
        if (path == "/upload" && method == "POST") {
            let message = "OK"
            let res = HTTPDataResponse(data: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true))
            return res
        }
        let res = super.httpResponseForMethod(method, URI: path)
        return res
    }
    
    /**
    Bodyを受け取る前処理
    - parameter contentLength: サイズ
    */
    override func prepareForBodyWithSize(contentLength: UInt64) {
        let contentType = request().headerField("Content-Type")
        Logger.debug("contentType=[\(contentType)]")
        let m = contentType.eMatch("^multipart/form-data; *boundary=(.+)");
        if (m.count > 0) {
            let boundary = m[1]
            Logger.debug("boundary:[\(boundary)]")
            parser = MultipartFormDataParser(boundary: boundary, formEncoding: NSUTF8StringEncoding)
            parser.delegate = self
            dstHandle = nil
        } else {
            parser = nil
        }
    }
    
    /**
    Bodyを受け取る
    - parameter postDataChunk: データ
    */
    override func processBodyData(postDataChunk: NSData!) {
        if (parser != nil) {
            parser.appendData(postDataChunk)
        }
    }
    
    
    // MARK: - MultipartFormDataParserDelegate method
    
    /**
    パート開始
    - parameter header: ヘッダ
    */
    func processStartOfPartWithHeader(header: MultipartMessageHeader!) {
        let dispField = header.fields["Content-Disposition"] as? MultipartMessageHeaderField
        if (dispField == nil) {
            dstHandle = nil
            return
        }
        let fileName = dispField?.params["filename"] as? String
        if (fileName == nil) {
            dstHandle = nil
            return
        }
        let dstPath = EG.docPath(fileName!)
        dstHandle = FileUtil.createFile(dstPath)
        Logger.debug(dstHandle, message:"dstPath:[\(dstPath)]")
    }
    
    /**
    パートデータ
    - parameter data:   データ
    - parameter header: ヘッダ
    */
    func processContent(data: NSData!, withHeader: MultipartMessageHeader!) {
        if (dstHandle != nil) {
            dstHandle.writeData(data)
        }
    }
    
    /**
    パート終了
    - parameter header: ヘッダ
    */
    func processEndOfPartWithHeader(header: MultipartMessageHeader!) {
        if (dstHandle != nil) {
            dstHandle.closeFile()
            dstHandle = nil
        }
    }
    /**
    なにもしない
    - parameter data: データ
    */
    func processPreambleData(data: NSData!) {
        
    }
    /**
    なにもしない
    - parameter data: データ
    */
    func processEpilogueData(data: NSData!) {
        
    }
    
   
}
