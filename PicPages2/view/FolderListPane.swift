//
//  FolderPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/12/06.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import UIKit

// フォルダ内のファイル、フォルダ一覧画面
class FolderListPane: AbstractFolderPane, UITableViewDataSource, UITableViewDelegate, FolderDelegate {

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var titleItem: UIBarButtonItem!
    
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var normalTopbar: UIToolbar!
    @IBOutlet weak var normalBottombar: UIToolbar!
    
    @IBOutlet weak var editTopbar: UIToolbar!
    @IBOutlet weak var editBottombar: UIToolbar!
    
    @IBOutlet weak var moveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    private var children: [Folder]?
    
    // MARK: - private methods
    private func loadData() {
        if (folder == nil) {
            backButton.enabled = false
            folder = Folder.rootFolder
            folder.delegate = self
        }
        titleItem.title = folder.name
        let app = AppDelegate.getInstance()
        children = folder.getChildren(logined: app.isLogined)
    }
    
    private func reloadTable() {
        loadData()
        table.reloadData()
        if (!table.editing && children != nil) {
            // lastReadの行を選択
            for i in 0 ..< children!.count {
                let c = children![i]
                if (c.id == folder!.lastRead) {
                    let idx = NSIndexPath(forRow: i, inSection: 0)
                    table.selectRowAtIndexPath(idx, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
                    break
                }
            }
        }
    }
    
    // ログインボタンの画像
    private func updateLoginCondition() {
        let app = AppDelegate.getInstance()
        if (app.isPasscodeSet && !app.isLogined) {
            loginButton.image = UIImage(named: "tbicon_lock.png")
        } else {
            loginButton.image = UIImage(named: "tbicon_unlock.png")
        }
        reloadTable()
    }
    // 選択、選択解除時にmoveとdeleteのenableを切り替える
    private func updateButtonsOnSelect() {
        var selected: Bool
        if (table.indexPathsForSelectedRows()?.count > 0) {
            selected = true
        } else {
            selected = false
        }
        deleteButton.enabled = selected
        moveButton.enabled = selected
    }
    
    // MARK: - public methods
    // 選択されているフォルダ一覧を返す
    func getSelectedFolders() -> [Folder] {
        var ret: [Folder] = []
        let sel = table.indexPathsForSelectedRows()
        if (sel != nil && (children?.count ?? 0) > 0) {
            for s in sel! {
                let ip = s as! NSIndexPath
                ret.append(children![ip.row])
            }
        }
        return ret
    }
    
    // MARK: - PaneBase
    
    /**
    バックグラウンドに入るとき実行する
    */
    override func onEnterBackground() {
        updateLoginCondition()
        super.onEnterBackground()
    }
    
    /**
    フォアグラウンドに入るとき実行する
    */
    override func onEnterForeground() {
        if (folder.id == 1) {
            // ルートフォルダの場合、画面表示ごとにimportを走らせる
            folder.importArchives()
        }
    }
    
    
    // MARK: - Event
    // 編集開始
    @IBAction func startEdit() {
        normalTopbar.eFadeout()
        editTopbar.eFadein()
        normalBottombar.eFadeout()
        editBottombar.eFadein()
        table.editing = true
        table.reloadInputViews()
        updateButtonsOnSelect()
    }
    // 編集完了
    @IBAction func endEdit() {
        editTopbar.eFadeout()
        normalTopbar.eFadein()
        editBottombar.eFadeout()
        normalBottombar.eFadein()
        table.editing = false
        table.reloadInputViews()
    }
    // 選択フォルダを削除する
    @IBAction func deleteFolders(sender: UIBarButtonItem) {
        EG.confirm(self, title: eR("Are you sure to delete?"), message: "", onOK: {
            for s in self.getSelectedFolders() {
                s.remove()
            }
            self.reloadTable()
            self.endEdit()
            }, onCancel: {})
    }
    
    // 選択フォルダを移動する
    @IBAction func moveFolders(sender: AnyObject) {
        if (table.indexPathsForSelectedRows()?.count > 0) {
            showCoverViewController("FolderSelectorPane")
        }
    }
    
    // 新しいフォルダを作成する
    @IBAction func makeNewFolder(sender: AnyObject) {
        EG.prompt(self,
            title: eR("Make new folder"),
            message: "",
            placeholder: eR("Folder name"),
            onOK: {text in
                let newFolder = self.folder.createChild(text)
                newFolder.save()
                self.reloadTable()
                self.endEdit()
            }, onCancel: {})
    }
    
    
    // ログインボタンのイベント
    @IBAction func loginAction(sender: UIBarButtonItem) {
        let app = AppDelegate.getInstance()
        if (app.isPasscodeSet) {
            if (app.isLogined) {
                let s = self
                let alert = UIAlertController(
                    title: eR("Logined"),
                    message: nil,
                    preferredStyle: .ActionSheet
                )
                alert.addAction(UIAlertAction(
                    title: eR("Logout"),
                    style: .Destructive,
                    handler: {
                        action in
                        app.logout()
                        s.updateLoginCondition()
                }))
                alert.addAction(UIAlertAction(
                    title: eR("Set pass code"),
                    style: .Default,
                    handler: {action in
                        s.showCoverViewController("PassSetPane")
                        return
                }))
                alert.addAction(UIAlertAction(title: eR("Preference"),
                    style: .Default,
                    handler: {action in
                        self.showCoverViewController("SettingsPane")
                        return
                }))
                alert.addAction(UIAlertAction(title: eR("Cancel"),
                    style: .Cancel,
                    handler: {action in}))
                presentViewController(alert, animated: true, completion: {})
            } else {
                showCoverViewController("LoginPane")
            }
        } else {
            showCoverViewController("PassSetPane")
        }
    }

    // showCoverViewControllerから復帰したイベント
    override func coveredViewControllerWillDismiss(pane: PaneBase) {
        if (pane.isKindOfClass(LoginPane)
            || pane.isKindOfClass(PassSetPane))
        {
            updateLoginCondition()
        } else if (pane.isKindOfClass(FolderSelectorPane)) {
            // 選択フォルダを移動する
            let ftp = pane as! FolderSelectorPane
            let dst = ftp.dstFolder
            if (dst != nil) {
                for sel in getSelectedFolders() {
                    sel.moveTo(dst!)
                }
                reloadTable()
                endEdit()
            }
        }
    }
    
    // MARK: - FolderDelegate
    func importStarted() {
        
    }
    
    func importCompleted(imported:Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.reloadTable()
        })
        if (imported) {
            folder.cacheArchives()
        }
    }
    
    func cacheCompleted(folder: Folder) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.reloadTable()
        })
    }
    
    // MARK: - UIViewController
    override func viewWillAppear(animated: Bool) {
        updateLoginCondition()
        if (folder.id == 1) {
            // ルートフォルダの場合、画面表示ごとにimportを走らせる
            folder.importArchives()
        }
    }
    
    // 読み込み時
    override func viewDidLoad() {
        super.viewDidLoad()
        table.rowHeight = 44;
        table.allowsMultipleSelectionDuringEditing = true
    }
    
    // メモリが足りない時
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        children = nil
        Logger.info(self, message: "memory warning")
    }

    // MARK: - Navigation

    // 画面遷移の準備
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        Logger.debug(segue.destinationViewController, message: "segue=[\(segue.identifier)]")
        var targetFolder :Folder!
        if (sender!.isKindOfClass(BookCell)) {
            targetFolder = (sender as! BookCell).folder
        } else if (sender!.isKindOfClass(FolderCell)) {
            targetFolder = (sender as! FolderCell).folder
        } else {
            targetFolder = folder
        }
        
        switch (segue.identifier ?? "") {
        case "Folder":
            // サブフォルダ
            let pane = segue.destinationViewController as! FolderListPane
            folder.lastRead = targetFolder.id
            pane.folder = targetFolder
        case "Book":
            // 本の表示
            var pane = segue.destinationViewController as! BookPane
            pane.folder = targetFolder
        case "Config", "Config2", "FolderConfig":
            // フォルダ設定
            var pane = segue.destinationViewController as! ConfigPane
            pane.folder = targetFolder
        case "FolderConfig":
            var pane = segue.destinationViewController as! ConfigPane
            pane.folder = folder
        default:
            break;
        }
    }
    
    // 画面遷移するかどうか
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        // 編集中は遷移しない
        if (table.editing) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - UITableViewDataSoruce
    
    //
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return children?.count ?? 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // セルの内容
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var fol = children![indexPath.row]
        if (!fol.cacheCompleted) {
            var cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell") as! LoadingCell
            cell.label.text = fol.name
            return cell
        } else if (fol.isBook) {
            var cell = tableView.dequeueReusableCellWithIdentifier("BookCell") as! BookCell
            cell.label.text = fol.name
            cell.folder = fol
            var book = Book(folder: fol)
            cell.thumbImage.image = book.thumbImage()
            if (fol.loginCondition == .Private) {
                cell.lockIcon.hidden = false
            } else {
                cell.lockIcon.hidden = true
            }
            return cell
        } else {
            var cell = tableView.dequeueReusableCellWithIdentifier("FolderCell") as! FolderCell
            cell.label.text = fol.name
            cell.folder = fol
            if (fol.loginCondition == .Private) {
                cell.lockIcon.hidden = false
            } else {
                cell.lockIcon.hidden = true
            }
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView.editing) {
            updateButtonsOnSelect()
        }
    }
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView.editing) {
            updateButtonsOnSelect()
        }
    }
}
