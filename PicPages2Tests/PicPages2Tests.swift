//
//  PicPagesTests.swift
//  PicPagesTests
//
//  Created by 藤田正訓 on 2014/11/24.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import UIKit
import XCTest

class PicPagesTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
    EGDBのテスト
    */
    func testEGDB() {
        // このソースコードからの相対パスで
        let dbPath = __FILE__.eDirname.eAddPath("data/test.db")
        let copyPath = __FILE__.eDirname.eAddPath("data/test_copy.db")
        FileUtil.rm(copyPath)
        let db = EGDB(dbPath: dbPath, copyTo:copyPath)
        // 全レコード削除
        db.delete("testTable", condition: [:])
        
        // INSERTでデータ作成
        let now = NSDate()
        db.insert("testTable", record: [
            "name": "Test Example",
            "birthday": "1999-12-31 23:59:59",
            "bool": false
            ])
        db.insert("testTable", record: [
            "name": "Masanori Fujita",
            "birthday": now,
            "bool": false
            ])
        db.insert("testTable", record: [
            "name": nil,
            "birthday": NSDate(timeIntervalSinceNow: -3600),
            "bool": true
            ])
        db.insert("testTable", record: [
            "name": "Masahiro",
            "birthday": "1999-12-31 23:59:59",
            "bool": false
            ])
        // 最後の行をとっておく
        var masahiro = db.lastInsertedRow()
        
        // SELECT
        var sql = "SELECT * FROM testTable WHERE name LIKE ? ORDER BY testTable_id"
        var params:[AnyObject?] = ["Masa%"]
        var records = db.queryRecords(sql, params:params)
        XCTAssert(records.count == 2, "records.count が2のはず")
        XCTAssert(records[0]["name"]! == "Masanori Fujita", "1つ目はMasanori Fujita")
        XCTAssert(records[1]["birthday"]! == "1999-12-31 23:59:59", "2つ目は世紀末")
        
        // whereCruise
        params = []
        sql = "SELECT * FROM testTable WHERE " + EGDB.whereCruise(["bool":true], params: &params)
        var record = db.queryRow(sql, params: params)
        XCTAssert(record!["name"] != nil, "キーが存在する")
        XCTAssert(record!["name"]! == nil, "nilが返されてる")
        
        // UPDATE
        db.update("testTable", condition: ["name":"Masahiro"], record: [
            "birthday": "2000-01-01 00:00:00",
            "bool": true
        ])
        
        // select系
        record = db.selectRow("testTable", condition: ["testTable_id":masahiro!["testTable_id"]!])
        XCTAssert(record!["birthday"]! == "2000-01-01 00:00:00", "UPDATE実行後")

        // ORDER BY
        records = db.selectRecords("testTable", condition: ["bool":false], order:"testTable_id desc")
        XCTAssert(records[0]["name"]! == "Masanori Fujita", "order逆順")
        XCTAssert(records[0]["birthday"]! == now.eFormat(), "order逆順")
        
        // ORDERなし
        records = db.selectRecords("testTable", condition:["bool":true])
        println("\(records)")
        XCTAssert(records.count == 2, "orderなし")
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
