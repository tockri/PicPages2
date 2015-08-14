//
//  LoginPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/25.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit
// ログイン画面
class LoginPane: PaneBase {
   
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    override func viewWillAppear(animated: Bool) {
        passText.becomeFirstResponder()
    }
    
    @IBAction func submit() {
        errorMessageLabel.hidden = true
        let app = AppDelegate.getInstance()
        if (app.tryLogin(passText.text)) {
            dismissCoveringViewController()
        } else {
            errorMessageLabel.hidden = false
        }
    }
}
