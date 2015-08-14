//
//  SettingsPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/25.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

class SettingsPane: PaneBase {
   
    @IBOutlet weak var rememberLoginSwitch: UISwitch!
    
    @IBAction func rememberLoginChanged(sender: UISwitch) {
        let app = AppDelegate.getInstance()
        app.rememberLogin = sender.on
    }
    
    override func viewDidLoad() {
        let app = AppDelegate.getInstance()
        rememberLoginSwitch.on = app.rememberLogin
    }
}
