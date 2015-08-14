//
//  FolderSelectorPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/28.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

// 移動先を選択する画面
class FolderSelectorPane: PaneBase, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var table: UITableView!
    
    // ツリーノードの内部クラス
    private class Node {
        var folder: Folder
        var depth: Int = 0
        
        init(f :Folder, d:Int) {
            folder = f
            depth = d
        }
    }
    private var currentFolder:Folder!
    private var parentSelected: [Folder] = []
    private var nodeList: [Node] = []
    var dstFolder: Folder?
    
    // MARK: - private methods
    
    // カレントフォルダと親FolderListPaneで選択されているFolderの子孫は選択肢に入れない
    private func isToAppend(folder: Folder) -> Bool {
        if (folder.id == currentFolder.id) {
            return false
        }
        
        for sel in parentSelected {
            if ((!sel.isBook && sel.isAncestorOf(folder)) || folder.id == sel.id) {
                return false
            }
        }
        
        return true
    }
    
    private func appendToChildren(folder: Folder, depth: Int) {
        let app = AppDelegate.getInstance()
        if (isToAppend(folder)) {
            nodeList.append(Node(f: folder, d: depth))
        }
        for cf in folder.getChildFolders(logined: app.isLogined) {
            appendToChildren(cf, depth: depth + 1)
        }
    }
    
    private func loadData() {
        appendToChildren(Folder.rootFolder, depth:0)
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        let flp = parentViewController as! FolderListPane
        parentSelected = flp.getSelectedFolders()
        currentFolder = flp.folder
        loadData()
    }
    
    // MARK: - UITableViewDataSource
    // 行数を返す
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return nodeList.count
        } else {
            return 0
        }
    }
    // セルを返す
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FolderSelectorCell") as! FolderSelectorCell
        let node = nodeList[indexPath.row]
        cell.nameLabel.text = node.folder.name
        // レイアウトを修正してdepthを表現する
        var toRemove: NSLayoutConstraint!
        for c in cell.contentView.constraints() {
            if (c.firstItem === cell.icon
                && c.firstAttribute == NSLayoutAttribute.Leading
                && c.secondItem! === cell.contentView
                && c.secondAttribute == NSLayoutAttribute.LeadingMargin)
            {
                // 削除する
                toRemove = c as! NSLayoutConstraint
                break
            }
        }
        if (toRemove != nil) {
            cell.contentView.removeConstraint(toRemove)
            cell.contentView.addConstraint(NSLayoutConstraint(
                item: cell.icon!,
                attribute: NSLayoutAttribute.Leading,
                relatedBy: NSLayoutRelation.Equal,
                toItem: cell.contentView,
                attribute: NSLayoutAttribute.LeadingMargin,
                multiplier: CGFloat(1),
                constant: CGFloat(node.depth * 28)))
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodeList[indexPath.row]
        dstFolder = node.folder
        dismissCoveringViewController()
    }

}
