//
//  PassSetPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/25.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

class PassSetPane: PaneBase {
   
    @IBOutlet weak var pass1Text: UITextField!
    @IBOutlet weak var pass2Text: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidAppear(animated: Bool) {
        pass1Text.becomeFirstResponder()
    }
    
    @IBAction func savePass() {
        errorMessageLabel.hidden = true
        if (pass1Text.text != "") {
            if (pass1Text.text == pass2Text.text) {
                let app = AppDelegate.getInstance()
                app.setPassCode(pass1Text.text!)
                dismissCoveringViewController()
            } else {
                errorMessageLabel.hidden = false
            }
        }
    }
}
