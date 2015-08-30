//
//  BookPagePane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/18.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

// BookPaneの1ページ分
class BookPagePane: PaneBase, UIScrollViewDelegate {
    private var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // 親BookPaneのbook参照
    weak var book:Book!
    // 画像の左側を表示する
    var left: Bool = false
    
    // ページ番号
    private var _page:Int = 1
    // 画像
    private var image: UIImage!
    
    private var _horizScroll :Bool = false
    
    // ページ数を設定すると画像を読み込む
    var page: Int {
        get {
            return _page
        }
        set {
            if (newValue == 0 || newValue == book.pageCount + 1) {
                _page = newValue
                image = nil
            } else if (1 <= newValue && newValue <= book.pageCount) {
                _page = newValue
                
                image = book.pageImageAt(_page)
            } else {
                image = nil
            }
            if (imageView != nil) {
                imageView.image = image
            }
        }
    }
    // 横長画像を表示している
    var isWide: Bool {
        if (image != nil) {
            var sz = image.size
            return sz.height < sz.width
        } else {
            return false
        }
    }
    // 左側にスクロール領域を残している
    var remainLeftScroll: Bool {
        return scrollView.contentOffset.x > 0
    }
    // 右側にスクロール領域を残している
    var remainRightScroll: Bool {
        return scrollView.contentOffset.x < imageView.eWidth - scrollView.eWidth
    }
    /// 上側にスクロール領域を残している
    var remainTopScroll: Bool {
        return scrollView.contentOffset.y > 0
    }
    /// 下側にスクロール領域を残している
    var remainBottomScroll: Bool {
        return scrollView.contentOffset.y < imageView.eHeight - scrollView.eHeight
    }
    
    
    /// 拡大表示しているかどうか
    var isZoomed: Bool {
        return scrollView.zoomScale > 1
    }
    
    // MARK: - private methods
    private func updateLayout() {
        let rw = view.eWidth
        let rh = view.eHeight
        var imgWidth: CGFloat
        var imgHeight: CGFloat
        _horizScroll = false
        if (isWide) {
            // 画像が横長
            if (rw < rh) {
                // 縦置き
                imgWidth = rw * 2
                imgHeight = rh
                _horizScroll = true
            } else {
                // 横置き
                imgWidth = rw
                imgHeight = rh
            }
        } else {
            // 画像が縦長
            if (rw < rh) {
                // 縦置き
                imgWidth = rw
                imgHeight = rh
            } else {
                // 横置き
                imgWidth = rw
                imgHeight = rh * 2
            }
        }
        scrollView.eFitToSuperview()
        imageView.frame = CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight)
        scrollView.contentSize = CGSize(width: imgWidth, height: imgHeight)
        if (_horizScroll) {
            if (left) {
                scrollTo(.LeftTop, animated: false)
            } else {
                scrollTo(.RightTop, animated: false)
            }
        }
    }
    
    private func logsize() {
        Logger.debug(view, message:"view")
        Logger.debug(scrollView, message:"scroll")
        Logger.debug(imageView, message:"image")
    }
    
    // MARK: - public methods
    
    /**
    スクロールする
    :param: scr スクロール方向
    :param: animated アニメーション
    */
    func scrollTo(scr:BookPane.ScrollDirection, animated:Bool = true) {
        var p = scrollView.contentOffset
        if (scr == .Left || scr == .LeftTop || scr == .LeftBottom) {
            p.x = 0
        } else if (scr == .Right || scr == .RightTop || scr == .RightBottom) {
            p.x = imageView.eWidth - scrollView.eWidth
        }
        if (scr == .Top || scr == .LeftTop || scr == .RightTop) {
            p.y = 0
        } else if (scr == .Bottom || scr == .LeftBottom || scr == .RightBottom) {
            p.y = imageView.eHeight - scrollView.eHeight
        }
        scrollView.setContentOffset(p, animated: animated)
    }
    
    /**
    ズームアップする
    :param: center 中心座標
    */
    func zoomUp(center: CGPoint) {
        let z = scrollView.maximumZoomScale
        scrollView.setZoomScale(z, animated: true)
        
        var p = CGPoint()
        p.x = (imageView.eWidth - scrollView.eWidth) * center.x
        p.y = (imageView.eHeight - scrollView.eHeight) * center.y
        scrollView.setContentOffset(p, animated:true)
    }
    
    /**
    ズームダウンする
    */
    func zoomDown() {
        scrollView.setZoomScale(1, animated: true)
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        automaticallyAdjustsScrollViewInsets = false
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        imageView = UIImageView(image: image)
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        // 仮のサイズ
        imageView.frame = CGRect(x: 0, y: 0, width: view.eWidth, height: view.eHeight)
        scrollView.addSubview(imageView)

    }

    override func viewWillAppear(animated: Bool) {
        updateLayout()
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        updateLayout()
    }

    // MARK: - UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBAction func back(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
}
