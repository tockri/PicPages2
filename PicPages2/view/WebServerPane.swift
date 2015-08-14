//
//  WebServerPane.swift
//  PicPages2
//
//  Created by 藤田正訓 on 2015/08/01.
//  Copyright (c) 2015年 sat. All rights reserved.
//

import UIKit


/// Webサーバーを起動する画面
class WebServerPane: PaneBase {
    
    @IBOutlet weak var urlLabel: UILabel!

    var server:HTTPServer!
    
    
    // MARK: - private methods
    
    /**
    サーバーを開始する
    */
    private func startServer() {
        let addr = EGNet.getLANAddress()
        if (addr != nil) {
            DDLog.addLogger(DDTTYLogger.sharedInstance())
            server = HTTPServer()
            server.setType("_http._tcp.")
            server.setPort(50000)
            server.setDocumentRoot(EG.resPath("htdocs"))
            server.setConnectionClass(UploaderConnection)
            var err: NSError? = nil
            if (!server.start(&err)) {
                Logger.warn(err, message: "http server failed")
                urlLabel.text = ""
                server = nil
            }
            let port = server.listeningPort()
            urlLabel.text = "http://\(addr!):\(port)/"
        } else {
            urlLabel.text = eR("WebServer is not started.  Connect LAN please.")
            server = nil
        }
    }
    
    /**
    サーバーを停止する
    */
    private func stopServer() {
        if (server != nil) {
            server.stop()
            server = nil
        }
    }
    
    // MARK: - public method
    @IBAction func backToRoot() {
        navigationController?.popToRootViewControllerAnimated(true)
    }

    
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        startServer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopServer()
    }
    
}
