//
//  ControlPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/21.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit
// BookPaneの操作画面
class ControlPane: PaneBase, UIGestureRecognizerDelegate {
    
    // MARK: - items
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var controlPanel: UIView!
    @IBOutlet weak var pageLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var leftButton: UIButton!
    
    @IBOutlet weak var rightButton: UIButton!
    private var pageCount:Int = 0
    
    // MARK: - private properties
    private var timer:NSTimer!
    
    // フォルダ
    private var folder: Folder {
        return bookPane.folder
    }
    // 本
    private var book: Book {
        return bookPane.book
    }
    // 親
    private var bookPane: BookPane {
        return parentViewController! as! BookPane
    }
    /// スライダーが表すページ番号
    private var sliderPage: Int {
        get {
            if (bookPane.folder.isLeftward) {
                return pageCount - Int(roundf(slider.value)) + 1
            } else {
                return Int(roundf(slider.value))
            }
        }
        set {
            if (bookPane.folder.isLeftward) {
                slider.value = Float(pageCount - newValue + 1)
            } else {
                slider.value = Float(newValue)
            }
            updatePageLabel()
        }
    }
    
    // MARK: - private methods
    
    /**
    タイトルバーとスライダーの色を更新する
    */
    private func updateViews() {
        titleLabel.text = folder.name
        pageCount = bookPane.folder.pageCount

        slider.maximumValue = Float(pageCount)
        sliderPage = bookPane.currentPage
        

        if (bookPane.folder.isLeftward) {
            slider.minimumTrackTintColor = UIColor.whiteColor()
            slider.maximumTrackTintColor = UIColor.orangeColor()
        } else {
            slider.minimumTrackTintColor = UIColor.orangeColor()
            slider.maximumTrackTintColor = UIColor.whiteColor()
        }
        
    }
    /**
    ページ番号を更新する
    */
    private func updatePageLabel() {
        pageLabel.text = "\(sliderPage) / \(pageCount)"
    }
    
    // MARK: - public methods
    
    /**
    フォルダに戻る
    */
    @IBAction func back(sender: AnyObject) {
        bookPane.back()
    }
    /**
    前の本
    */
    @IBAction func up(sender: AnyObject) {
        bookPane.goPrev()
        updateViews()
//        updatePageLabel()
    }
    /**
    次の本
    */
    @IBAction func down(sender: AnyObject) {
        bookPane.goNext()
        updateViews()
//        updatePageLabel()
    }
    /**
    左のページ
    */
    @IBAction func left(sender: AnyObject) {
        bookPane.pageLeft(false)
        sliderPage = bookPane.currentPage
//        updateViews()
    }

    /**
    右のページ
    */
    @IBAction func right(sender: AnyObject) {
        bookPane.pageRight(false)
        sliderPage = bookPane.currentPage
//        updateViews()
    }
    
    
    // タップされたイベント
    @IBAction func tapped(gr: UITapGestureRecognizer) {
        if (gr.view?.superview == self.view) {
            bookPane.dismissControl()
        }
    }
    /**
    スライダーの値が変わったイベント
    :param: sender スライダー
    */
    @IBAction func sliderChanged(sender:AnyObject) {
        let rv = roundf(slider.value)
        if (rv != slider.value) {
            slider.value = rv
        }
        updatePageLabel()
        // スライダーが止まってから0.3秒後にページ切り替え
        if (timer != nil) {
            timer.invalidate()
            timer = nil
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self,
            selector: "sliderTimerUpdated:", userInfo: nil, repeats: false)
    }
    
    /**
    本の削除
    */
    @IBAction func deleteFolder() {
        EG.confirm(self, title: eR("Are you sure to delete?"), message: "", onOK: {
            let f = self.folder
            self.bookPane.goNext()
            f.remove()
            if (self.folder.id == f.id) {
                // もう残っていない場合
                self.bookPane.back()
            } else {
                self.updateViews()
            }
            }, onCancel: {})
    }
    
    /**
    スライダーによりページ変更
    :param: t タイマー
    */
    func sliderTimerUpdated(t:NSTimer) {
        if (t == timer) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.bookPane.showPage(self.sliderPage, animated: false)
            })
            self.timer = nil
        }
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isDescendantOfView(controlPanel)) {
            return false
        }
        return true
    }
    
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        controlPanel.eCornerRadius(4)
        leftButton.eCornerRadius(3)
        rightButton.eCornerRadius(3)
    }
    
    override func viewWillAppear(animated: Bool) {
        updateViews()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch (segue.identifier!) {
        case "Config":
            let pane = segue.destinationViewController as! ConfigPane
            pane.folder = folder
            bookPane.dismissControl()
        default:
            break
        }
    }
    
    
}
