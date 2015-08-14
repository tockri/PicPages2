//
//  EGDB.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/17.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import Foundation

/// SQLite3ラッパー
public class EGDB: NSObject {
    private let lockObject = NSObject()
    private let dbFile:String
    private let copyDbFile:String
    private var lastInsertTable:String?
    private var db:COpaquePointer = nil
    
    /**
    コンストラクタ
    :param: dbName DBファイル名。リソース
    :param: copyToCache cacheディレクトリにコピーしてから使用する
    */
    init(dbPath:String, copyTo:String = "") {
        dbFile = dbPath
        copyDbFile = copyTo
        if (!FileUtil.exists(dbFile)) {
            println("dbPath is not exist:\(dbPath)")
        }
    }
    /**
    オブジェクト破棄時にcloseする
    */
    deinit {
        closeDb()
    }
    
    /**
    DBをオープンする
    :returns: DBポインタ
    */
    private func openDb() {
        if (db == nil) {
            if (copyDbFile != "") {
                if (!FileUtil.exists(copyDbFile)) {
                    FileUtil.copy(dbFile, to: copyDbFile)
                }
                sqlite3_open(copyDbFile, &db)
            } else {
                sqlite3_open(dbFile, &db)
            }
        }
    }
    /**
    DBをクローズする
    */
    public func closeDb() {
        if (db != nil) {
            sqlite3_close_v2(db)
            db = nil
            lastInsertTable = nil
            println("db successfully closed.")
        }
    }
    /**
    プリペアドステートメントを生成する
    :param: sql SQLクエリ
    :returns: sqlite3_statementポインタ
    */
    private func prepare(db:COpaquePointer, sql:String) -> COpaquePointer {
        var stmt: COpaquePointer = nil
        let resCode = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if (resCode == SQLITE_OK) {
            return stmt
        } else {
            sqlite3_finalize(stmt)
            println("SQLite Error : " + EGDB.errorMessageFromCode(resCode))
            return nil
        }
    }
    /**
    クエリを実行する
    :param: sql    SQLクエリ
    :param: params パラメータ
    :return: sqlite3_statementポインタ
    */
    private func queryInner(db:COpaquePointer, sql:String, params:[AnyObject?]?) -> COpaquePointer {
        let stmt = prepare(db, sql:sql)
        if (stmt != nil) {
            if (params != nil) {
                for var i = 1; i <= params!.count; i++ {
                    bind(stmt, idx: CInt(i), value: params![i - 1])
                }
            }
        }
        return stmt
    }
    
    private func bind(stmt:COpaquePointer, idx:CInt, value:AnyObject?) {
        var resCode:Int32
        if (value == nil) {
            resCode = sqlite3_bind_null(stmt, idx)
        } else {
            var vtext:String
            if (value! is NSDate) {
                vtext = (value as! NSDate).eFormat()
            } else {
                vtext = eS(value!)
            }
            let negativeOne = UnsafeMutablePointer<Int>(bitPattern: -1)
            let opaquePointer = COpaquePointer(negativeOne)
            let transient = CFunctionPointer<((UnsafeMutablePointer<()>) -> Void)>(opaquePointer)
            resCode = sqlite3_bind_text(stmt, idx, vtext, -1, transient)
        }
        if (resCode != SQLITE_OK) {
            println("SQLite Error : " + EGDB.errorMessageFromCode(resCode))
        }
    }
    
    /**
    クエリを実行する（更新系）
    :param: sql    SQL
    :param: params パラメータ
    */
    public func query(sql:String, params:[AnyObject?]? = nil, callback:(([String:String?])->Bool)? = nil) {
        objc_sync_enter(lockObject)
        openDb()
        let stmt = queryInner(db, sql: sql, params: params)
        var next = true
        while next {
            let resCode = sqlite3_step(stmt)
            if (resCode == SQLITE_OK || resCode == SQLITE_DONE) {
                // nop
                next = false
            } else if (resCode == SQLITE_ROW) {
                if (callback != nil) {
                    let colCount:Int32 = sqlite3_column_count(stmt)
                    var record = [String:String?]()
                    for var c:Int32 = 0; c < colCount; c++ {
                        let colName = String.fromCString(UnsafePointer<Int8>(sqlite3_column_name(stmt, c)))!
                        let colValue = String.fromCString(UnsafePointer<Int8>(sqlite3_column_text(stmt, c)))
                        record[colName] = colValue
                    }
                    next = callback!(record)
                } else {
                    next = false
                }
            } else {
                // error
                println("SQLite Error : " + EGDB.errorMessageFromCode(resCode))
                next = false
            }
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(lockObject)
    }
    
    /**
    一行分のレコードを返す
    :param: sql    SQL
    :param: params パラメータ
    :returns: レコード。見つからない場合はnil
    */
    public func queryRow(sql:String, params:[AnyObject?]? = nil) -> [String:String?]? {
        var ret:[String:String?]? = nil
        query(sql, params: params) { (record) -> Bool in
            ret = record
            return false
        }
        return ret
    }
    
    /**
    複数行のレコードを返す
    :param: sql    SQL
    :param: params パラメータ
    :returns: レコードの配列。見つからない場合は空配列
    */
    public func queryRecords(sql:String, params:[AnyObject?]? = nil) -> [[String:String?]] {
        var ret = [[String:String?]]()
        query(sql, params: params) { (record) -> Bool in
            ret.append(record)
            return true
        }
        return ret
    }
    /**
    一行分のレコードの最初のカラムを返す
    :param: sql    SQL
    :param: params パラメータ
    :returns: レコード。見つからない場合はnil
    */
    public func queryValue(sql:String, params:[AnyObject?]? = nil) -> String? {
        var ret:String? = nil
        query(sql, params: params) { (record) -> Bool in
            ret = record[Array(record.keys)[0]]!
            return false
        }
        return ret
    }
    /**
    全レコードの所定のフィールドを配列で返す
    :param: sql     SQL
    :param: params  パラメータ
    :param: colName 返すカラム名
    :returns: フィールドの配列
    */
    public func queryColumn(sql:String, colName:String, params:[AnyObject?]? = nil) -> [String] {
        var ret = [String]()
        query(sql, params: params) { (record) -> Bool in
            let value = record[colName]
            if (value != nil) {
                ret.append(record[colName]!!)
            }
            return true
        }
        return ret
    }
    
    /**
    SELECT文を実行して一行ごとにコールバック関数を実行する
    :param: tableName テーブル名
    :param: condition 検索条件
    :param: callback  コールバック
    :param: order     ORDER BY
    */
    public func select(tableName:String, condition:[String:AnyObject?], callback: (([String:String?])->Bool), order:String = "") {
        var params = [AnyObject?]()
        var sql = "SELECT * FROM `\(tableName)` WHERE " + EGDB.whereCruise(condition, params: &params)
        if (order != "") {
            sql += " ORDER BY \(order)"
        }
        query(sql, params: params, callback: callback)
    }
    
    /**
    最も一般的なSELECT文を作って実行する
    :param: tableName テーブル名
    :param: condition 検索条件
    :param: order     ORDER BY
    :returns: 検索結果（全レコード）
    */
    public func selectRecords(tableName:String, condition:[String:AnyObject?], order:String = "") -> [[String:String?]] {
        var params = [AnyObject?]()
        var sql = "SELECT * FROM `\(tableName)` WHERE " + EGDB.whereCruise(condition, params: &params)
        if (order != "") {
            sql += " ORDER BY \(order)"
        }
        return queryRecords(sql, params: params)
    }
    
    /**
    最も一般的なSELECT文を作って実行する
    :param: tableName テーブル名
    :param: condition 検索条件
    :returns: 検索結果（一行）
    */
    public func selectRow(tableName:String, condition:[String:AnyObject?]) -> [String:String?]? {
        var params = [AnyObject?]()
        var sql = "SELECT * FROM `\(tableName)` WHERE " + EGDB.whereCruise(condition, params: &params)
        return queryRow(sql, params: params)
    }
    
    /**
    UPDATE文を便利に作って実行する
    :param: table     テーブル名
    :param: condition 検索条件
    :param: record    保存するレコード
    */
    public func update(table:String, condition:[String:AnyObject?], record:[String:AnyObject?]) {
        var sqla = ["UPDATE `\(table)` SET "]
        var params = [AnyObject?]()
        var first = true
        for (key, value) in record {
            if (first) {
                first = false
            } else {
                sqla.append(",")
            }
            sqla.append(" `\(key)` = ? ")
            params.append(value)
        }
        sqla.append(" WHERE ")
        sqla.append(EGDB.whereCruise(condition, params:&params))
        let sql = join("", sqla)
        query(sql, params: params)
    }
    
    /**
    INSERT文を便利に作って実行する
    :param: table  テーブル名
    :param: record 保存するレコード
    */
    public func insert(table:String, record:[String:AnyObject?]) {
        var params = [AnyObject?]()
        var keys = [String]()
        var values = [String]()
        for (key, value) in record {
            keys.append("`\(key)`")
            values.append("?")
            params.append(value)
        }
        var sqla = ["INSERT INTO `\(table)` (",
            join(", ", keys),
            ") VALUES (",
            join(", ", values),
            ")"
        ]
        let sql = join("", sqla)
        query(sql, params: params)
        lastInsertTable = table
    }

    /**
    DELETE文を便利に作って実行する
    :param: table     テーブル名
    :param: condition 検索条件
    */
    public func delete(table:String, condition:[String:AnyObject?]) {
        var sqla = ["DELETE FROM `\(table)` WHERE "]
        var params = [AnyObject?]()
        sqla.append(EGDB.whereCruise(condition, params: &params))
        let sql = join("", sqla)
        query(sql, params:params)
    }
    /**
    いまINSERTしたばかりのレコードを返す
    */
    public func lastInsertedRow() -> [String:String?]? {
        if (lastInsertTable != nil) {
            var sql = "SELECT * FROM `\(lastInsertTable!)` WHERE ROWID = last_insert_rowid()"
            return queryRow(sql)
        } else {
            return nil
        }
    }
    
    /**
    テーブル名の配列を返す
    :returns: 全テーブル名
    */
    public func existingTables() -> [String] {
        let sql = "SELECT name FROM sqlite_master WHERE type = 'table'"
        return queryColumn(sql, colName: "name")
    }
    /**
    WHERE文に使える形のSQL条件節を作る
    :param: condition 条件
    :returns: SQL条件節
    */
    public static func whereCruise(condition:[String:AnyObject?], inout params:[AnyObject?]) -> String {
        var sqla = ["1=1"]
        var first = true
        for (key, value) in condition {
            sqla.append(" AND ")
            if (key.eSub(0, len: 1) == "?") {
                sqla.append(eS(value!))
            } else {
                let elems = key.eSplit(" ")
                var col = elems[0]
                var op = elems.count == 1 ? "=" : elems[1]
                sqla.append(" \(col) \(op) ? ")
                params.append(value)
            }
        }
        return join("", sqla)
    }
    
    /**
    エラーメッセージ
    :param: errorCode エラーコード
    :returns: メッセージ
    */
    private static func errorMessageFromCode(errorCode: Int32) -> String {
        
        switch errorCode {
            
            //no error
            
        case -1:
            return "No error"
            
            //SQLite error codes and descriptions as per: http://www.sqlite.org/c3ref/c_abort.html
        case 0:
            return "Successful result"
        case 1:
            return "SQL error or missing database"
        case 2:
            return "Internal logic error in SQLite"
        case 3:
            return "Access permission denied"
        case 4:
            return "Callback routine requested an abort"
        case 5:
            return "The database file is locked"
        case 6:
            return "A table in the database is locked"
        case 7:
            return "A malloc() failed"
        case 8:
            return "Attempt to write a readonly database"
        case 9:
            return "Operation terminated by sqlite3_interrupt()"
        case 10:
            return "Some kind of disk I/O error occurred"
        case 11:
            return "The database disk image is malformed"
        case 12:
            return "Unknown opcode in sqlite3_file_control()"
        case 13:
            return "Insertion failed because database is full"
        case 14:
            return "Unable to open the database file"
        case 15:
            return "Database lock protocol error"
        case 16:
            return "Database is empty"
        case 17:
            return "The database schema changed"
        case 18:
            return "String or BLOB exceeds size limit"
        case 19:
            return "Abort due to constraint violation"
        case 20:
            return "Data type mismatch"
        case 21:
            return "Library used incorrectly"
        case 22:
            return "Uses OS features not supported on host"
        case 23:
            return "Authorization denied"
        case 24:
            return "Auxiliary database format error"
        case 25:
            return "2nd parameter to sqlite3_bind out of range"
        case 26:
            return "File opened that is not a database file"
        case 27:
            return "Notifications from sqlite3_log()"
        case 28:
            return "Warnings from sqlite3_log()"
        case 100:
            return "sqlite3_step() has another row ready"
        case 101:
            return "sqlite3_step() has finished executing"
            
            //custom SwiftData errors
            
            //->binding errors
            
        case 201:
            return "Not enough objects to bind provided"
        case 202:
            return "Too many objects to bind provided"
        case 203:
            return "Object to bind as identifier must be a String"
            
            //->custom connection errors
            
        case 301:
            return "A custom connection is already open"
        case 302:
            return "Cannot open a custom connection inside a transaction"
        case 303:
            return "Cannot open a custom connection inside a savepoint"
        case 304:
            return "A custom connection is not currently open"
        case 305:
            return "Cannot close a custom connection inside a transaction"
        case 306:
            return "Cannot close a custom connection inside a savepoint"
            
            //->index and table errors
            
        case 401:
            return "At least one column name must be provided"
        case 402:
            return "Error extracting index names from sqlite_master"
        case 403:
            return "Error extracting table names from sqlite_master"
            
            //->transaction and savepoint errors
            
        case 501:
            return "Cannot begin a transaction within a savepoint"
        case 502:
            return "Cannot begin a transaction within another transaction"
            
            //unknown error
            
        default:
            //what the fuck happened?!?
            return "Unknown error"
        }
        
    }

    
}
