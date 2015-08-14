//
//  ConfigPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/22.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

class ConfigPane: AbstractFolderPane {
   
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var orientationButtons: UISegmentedControl!
    @IBOutlet weak var needsLoginSwitch: UISwitch!
    
    @IBOutlet weak var leftwardLabel: UILabel!
    @IBOutlet weak var rightwardLabel: UILabel!

    
    // 保存
    @IBAction func save(sender: UIBarButtonItem) {
        folder.name = titleText.text
        var o :Folder.PageOrientation
        switch (orientationButtons.selectedSegmentIndex) {
        case 0:
            o = .Left
        case 1:
            o = .Inherit
        case 2:
            fallthrough
        default:
            o = .Right
        }
        folder.pageOrientation = o
        folder.loginCondition = needsLoginSwitch.on ? .Private : .Inherit
        folder.save()
        navigationController?.popViewControllerAnimated(true)
    }
    // キャンセル
    @IBAction func back(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    // ページ方向のシミュレート
    @IBAction func orientationChanged(sender: UISegmentedControl) {
        var left: Bool
        switch (orientationButtons.selectedSegmentIndex) {
        case 0:
            left = true
        case 1:
            left = folder.parentFolder?.isLeftward ?? false
        case 2:
            fallthrough
        default:
            left = false
        }
        leftwardLabel.hidden = !left
        rightwardLabel.hidden = left
    }
    
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        titleText.text = folder.name
        var idx = 1
        switch (folder.pageOrientation) {
        case .Inherit:
            idx = 1
        case .Left:
            idx = 0
        case .Right:
            idx = 2
        }
        if (folder.parentFolder == nil) {
            orientationButtons.setEnabled(false, forSegmentAtIndex: 1)
            needsLoginSwitch.enabled = false
        }
        orientationButtons.selectedSegmentIndex = idx
        needsLoginSwitch.on = (folder.loginCondition == .Private)
        let app = AppDelegate.getInstance()
        if (app.isLogined) {
            needsLoginSwitch.enabled = true
        } else {
            needsLoginSwitch.enabled = false
        }
        orientationChanged(orientationButtons)
    }
}
