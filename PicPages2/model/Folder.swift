//
//  Folder.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/11/24.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import Foundation

protocol FolderDelegate {
    /**
    importが開始したとき呼ばれる
    */
    func importStarted();
    /**
    importが終わったとき呼ばれる
    */
    func importCompleted(imported:Bool);
    /**
    キャッシュが終わった時呼ばれる
    - parameter folder: キャッシュし終わったFolder
    */
    func cacheCompleted(folder:Folder);
}

// フォルダオブジェクト
class Folder : NSObject {
    // MARK: - enum
    /**
    ページめくり方向
    - Inherit: 親フォルダと同じ
    - Left:  左めくり
    - Right: 右めくり
    */
    enum PageOrientation :Int {
        case Inherit = 0,
        Left = 1,
        Right = 2
    }
    /**
    ログイン必要性
    - Inherit: 親フォルダと同じ
    - Private: ログイン必要
    */
    enum LoginCondition :Int {
        case Inherit = 0,
        Private = 1
    }
    
    // MARK: - static properties
    
    // ルートフォルダのシングルトンインスタンスを返す
    class var rootFolder: Folder {
        struct S {
            static var root: Folder?
        }
        if (S.root == nil) {
            S.root = Folder.folderById(1)
        }
        return S.root!
    }
    
    // MARK: - instance properties
    
    /// イベントを受け取るオブジェクト
    var delegate: FolderDelegate?
    private var importing = false
    private var caching = false
    private var parent: Folder?
    private var record:[String:String?]
    private var change:[String:AnyObject?]
    private var next: Folder?
    private var prev: Folder?
    
    // EGDBインスタンス
    private var db: EGDB {
        return PicPagesModel.Db
    }
    
    
    // 次のフォルダ
    var nextFolder: Folder? {
        return next
    }
    // 前のフォルダ
    var prevFolder: Folder? {
        return prev
    }
    // 次のis_bookであるフォルダ
    var nextBookFolder: Folder? {
        var n = next
        while (n != nil && (!n!.isBook || !n!.cacheCompleted)) {
            n = n?.next
        }
        return n
    }
    // 前のis_bookであるフォルダ
    var prevBookFolder: Folder? {
        var n = prev
        while (n != nil && !n!.isBook) {
            n = n?.prev
        }
        return n
    }
    
    // フォルダID
    var id: Int {
        if (record["folder_id"] == nil) {
            return 0
        } else {
            return Int(record["folder_id"]!!)!
        }
    }
    // フォルダの名前
    var name: String? {
        get {
            return record["name"]!
        }
        set {
            let v = newValue ?? Optional<String>()
            record["name"] = v
            change["name"] = v
        }
    }
    /// 取り込み元のファイル名
    var originalName: String? {
        get {
            return record["original_name"]!
        }
        set {
            let v = newValue ?? Optional<String>()
            record["original_name"] = v
            change["original_name"] = v
        }
    }
    // 親フォルダ
    var parentFolder: Folder? {
        if (parent == nil && id > 1) {
            let pathElems = path.eSplit("/")
            let parentId = Int(pathElems[pathElems.count - 1])!
            parent = Folder.folderById(parentId)
        }
        return parent
    }
    // パス
    private var path: String {
        get {
            return record["path"]!!
        }
        set {
            let v = newValue ?? Optional<String>()
            record["path"] = v
            change["path"] = v
        }
    }
    // コンテンツキャッシュのフォルダ名
    private var realName: String? {
        get {
            return record["real_name"]!
        }
        set {
            let v = newValue ?? Optional<String>()
            record["real_name"] = v
            change["real_name"] = v
        }
    }
    // コンテンツキャッシュディレクトリの実パス
    var realPath: String? {
        let rn = realName
        if (rn != nil && rn != "") {
            return EG.cachePath("book").eAddPath(rn!)
        } else {
            return nil
        }
    }
    
    // 本である
    var isBook: Bool {
        get {
            return record["is_book"]! == "1"
        }
        set {
            let v = newValue ? "1" : "0"
            record["is_book"] = v
            change["is_book"] = v
        }
    }
    // 移動可能である
    var isMovable: Bool {
        get {
            return record["is_movable"]! == "1"
        }
        set {
            let v = newValue ? "1" : "0"
            record["is_movable"] = v
            change["is_movable"] = v
        }
    }
    // ログインが必要である
    var loginCondition: LoginCondition {
        get {
            let r:Int = Int(record["login_condition"]!!) ?? 0
            return LoginCondition(rawValue: r)!
        }
        set {
            let v = eS(newValue.rawValue)
            record["login_condition"] = v
            change["login_condition"] = v
        }
    }
    // 親フォルダの設定を評価してログイン必要かどうかを返す
    var needsLogin: Bool {
        if (loginCondition == .Inherit) {
            return parentFolder?.needsLogin ?? false
        } else {
            return true
        }
    }
    
    // このfolderに設定されているページめくり方向
    var pageOrientation: PageOrientation {
        get {
            let r:Int = Int(record["page_orientation"]! ?? "0") ?? 0
            return PageOrientation(rawValue: r)!
        }
        set {
            let v = eS(newValue.rawValue)
            record["page_orientation"] = v
            change["page_orientation"] = v
        }
    }
    // 親フォルダの設定を再帰的に評価して左めくりかどうかを返す
    var isLeftward: Bool {
        if (pageOrientation == .Inherit) {
            return parent?.isLeftward ?? false
        } else {
            return pageOrientation == .Left
        }
    }
    // 最後に読んだページ
    var lastRead: Int {
        get {
            return  Int(record["last_read"]! ?? "1") ?? 1
        }
        set {
            let v = eS(newValue)
            record["last_read"] = v
            change["last_read"] = v
        }
    }
    // ページ数
    var pageCount: Int {
        get {
            return Int(record["page_count"]! ?? "0") ?? 0
        }
        set {
            let v = eS(newValue)
            record["page_count"] = v
            change["page_count"] = v
        }
    }
    /// キャッシュ生成完了しているかどうか
    var cacheCompleted: Bool {
        get {
            let c = record["cache_completed"]!
            return c == "1"
        }
        set {
            let v = newValue ? "1" : "0"
            record["cache_completed"] = v
            change["cache_completed"] = v
        }
    }
    
    // MARK: - constructor
    // レコードをもとに生成する
    private init(parentFolder:Folder?, folderRecord:[String: String?]) {
        record = folderRecord
        parent = parentFolder
        change = [:]
    }
    
    /**
    新しいフォルダを作成する
    - parameter parentFolder:    親フォルダ
    - parameter name:            フォルダ名
    - parameter realName:        ファイルの場合、新しい物理名を指定
    - parameter originalName:    ファイルの場合、元のファイル名を指定
    - parameter isBook:          直下にディレクトリがない場合はtrueを指定
    - parameter isMovable:       アーカイブ中のフォルダの場合falseを指定
    - parameter loginCondition:  指定しない（.Inherit）
    - parameter pageOrientation: 指定しない（.Inherit）
    - returns: 新しいフォルダ。未セーブ
    */
    private init(parentFolder:Folder, name:String, realName:String? = nil,
        originalName:String? = nil, isBook:Bool = false, isMovable:Bool = true,
        loginCondition:LoginCondition = .Inherit,
        pageOrientation:PageOrientation = .Inherit) {
            record = [
                "name": name,
                "real_name": realName,
                "original_name": originalName,
                "is_book": isBook ? "1" : "0",
                "is_movable": isMovable ? "1" : "0",
                "login_condition": eS(loginCondition.rawValue),
                "page_orientation": eS(pageOrientation.rawValue),
                "path": "\(parentFolder.path)\(parentFolder.id)/",
                "cache_completed": isBook ? "0" : "1"
            ]
            parent = parentFolder
            change = [:]
            for (key, value) in record {
                change[key] = value
            }
    }
    
    //MARK: - private methods
    /**
    Folder配列を返す
    - parameter condition: 検索条件
    - returns: Folderオブジェクト配列
    */
    private func getFolders(condition:[String:AnyObject?], order:String = "name") -> [Folder] {
        var ret: [Folder] = []
        var last: Folder? = nil
        db.select("folder", condition: condition, callback: { (record) -> Bool in
            let f = Folder(parentFolder:self, folderRecord:record)
            ret.append(f)
            if (last != nil) {
                last!.next = f
                f.prev = last
            }
            last = f
            return true
        }, order: order)
        if (ret.count > 0) {
            ret[0].prev = last
            last!.next = ret[0]
        }
        return ret
    }
    
    /**
    ルートフォルダの場合Documentsディレクトリ以下にあるファイルを取り込む
    */
    func importArchives() {
        if (id != 1 || importing) {
            return
        }
        importing = true
        let dir = EG.docPath("")
        let files = FileUtil.tree(dir)
        if (files.count == 0) {
            importing = false
            delegate?.importCompleted(false)
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            self.delegate?.importStarted()
            for file in files {
                let path = dir.eAddPath(file)
                if (Archiver.isArchivable(path)) {
                    let realName = NSDate().eFormat("yyyyMMddHHmmss") + eS(Int(rand() % 100))
                    let origName = file
                    let folder = Folder(parentFolder: self, name: origName.eBasename, realName: realName,
                        originalName: origName, isBook: true)
                    let realPath = folder.realPath!
                    FileUtil.mkdir(realPath)
                    if (FileUtil.mv(path, to: realPath.eAddPath(origName))) {
                        folder.save()
                    } else if (FileUtil.exists(path)) {
                        FileUtil.rm(path)
                    }
                } else {
                    FileUtil.rm(path)
                }
            }
            self.delegate?.importCompleted(true)
            self.importing = false
        })
    }
    /**
    取り込んだファイルをキャッシュする
    */
    func cacheArchives() {
        if (caching) {
            return
        }
        caching = true
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            while true {
                let condition:[String:AnyObject?] = [
                    "path":"\(self.path)\(self.id)/",
                    "cache_completed":0
                ]
                let uncached = self.getFolders(condition)
                if (uncached.count == 0) {
                    break
                } else {
                    for fol in uncached {
                        let arc = Archiver.archiverFor(fol)
                        if (arc != nil) {
                            if (arc!.extract()) {
                                self.delegate?.cacheCompleted(fol)
                            } else {
                                fol.remove()
                            }
                        }
                    }
                }
            }
            self.caching = false
        })
    }
    
    
    //MARK: - public methods
    
    /**
    子フォルダを作る
    - parameter name: フォルダ名
    - returns: フォルダインスタンス
    */
    func createChild(name:String) -> Folder {
        return Folder(parentFolder: self, name: name)
    }
    
    /**
    DBからレコードを再取得する
    */
    func reload() {
        record = db.selectRow("folder", condition: ["folder_id":id])!
        change = [:]
    }
    

    
    /**
    子フォルダのうちBookでないものの配列を生成して返す
    - parameter logined: ログイン中はtrueを指定する。
    - returns: フォルダ配列
    */
    func getChildFolders(logined:Bool = false) -> [Folder] {
        var condition:[String:AnyObject?] = [
            "path":"\(path)\(id)/",
            "is_book": 0,
        ]
        if (!logined) {
            condition["login_condition"] = 0
        }
        return getFolders(condition, order:"name")
    }
    
    /**
    子フォルダの配列を生成して返す
    - parameter logined: 現在ログイン中の場合trueを指定する。falseが指定された場合、要ログインの
    フォルダを除いた一覧を返す。
    - returns: フォルダ配列
    */
    func getChildren(logined:Bool = false) -> [Folder] {
        var condition:[String:AnyObject?] = [
            "path":"\(path)\(id)/",
        ]
        if (!logined) {
            condition["login_condition"] = 0
        }
        return getFolders(condition, order:"name")
    }
    
    /**
    DBに保存する
    */
    func save() {
        if (change.count > 0) {
            if (id > 0) {
                db.update("folder", condition: ["folder_id":id], record: change)
            } else {
                db.insert("folder", record: change)
                record = db.lastInsertedRow()!
            }
            change = [:]
        }
    }
    /**
    フォルダを削除する
    */
    func remove() {
        if (id == 1) {
            // rootは削除できない
            return
        }
        if (isBook) {
            // real_pathを削除
            let rp = realPath
            if (rp != nil && FileUtil.exists(rp!)) {
                FileUtil.rm(rp!)
            }
        } else {
            // 子孫Folderを全て削除
            let folders = getFolders(["path LIKE":"\(path)\(id)/"])
            for f in folders {
                f.remove()
            }
        }
        db.delete("folder", condition: ["folder_id":id])
        next?.prev = prev
        prev?.next = next
    }
    
    /**
    先祖フォルダかどうかを返す
    - parameter other: 対象フォルダ
    - returns: このフォルダが対象フォルダの先祖であればtrue
    */
    func isAncestorOf(other: Folder) -> Bool {
        let rs = other.path.rangeOfString("/\(id)/")
        return rs != nil
    }
    
    /**
    フォルダを移動する
    - parameter dst: 移動先フォルダ
    */
    func moveTo(dst: Folder) {
        if (id == 1) {
            // rootは移動できない
            return
        }
        // 子孫フォルダのpathを置換
        let srcPath = "\(path)\(id)/"
        let dstPath = "\(dst.path)\(dst.id)/"
        let sql = "UPDATE folder SET "
            + " path = replace(path, '\(srcPath)', '\(dstPath)\(id)/') "
            + " WHERE path LIKE '\(srcPath)%'"
        db.query(sql)
        // 自分のpathを変更
        path = dstPath
        save()
    }
    
    // MARK: - static methods
    
    /**
    IDを指定してFolderオブジェクトを生成して返す
    - parameter id: ID
    - returns: インスタンス
    */
    class func folderById(id: Int) -> Folder {
        let record = PicPagesModel.Db.selectRow("folder", condition: ["folder_id":id])!
        return Folder(parentFolder: nil, folderRecord: record)
    }
    
}
