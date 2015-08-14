//
//  PicPagesModel.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/16.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

/// DBアクセス基本クラス
class PicPagesModel : NSObject {
    private let DBNAME = "picpages.db"
    /// Singleton
    class var Instance: PicPagesModel {
        struct S {
            static var s = PicPagesModel()
        }
        return S.s
    }
    /// EGDBインスタンスを返す
    class var Db: EGDB {
        return PicPagesModel.Instance.db
    }
    
    /// DBインスタンス
    private let db:EGDB

    /**
    コンストラクタ
    :returns: インスタンス
    */
    private override init() {
        let cachePath = EG.cachePath("db/\(DBNAME)")
        db = EGDB(dbPath: EG.resPath(DBNAME), copyTo:cachePath)
    }
}
