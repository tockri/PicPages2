//
//  BookPane.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/01/17.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit

// 本を表示する画面
class BookPane : AbstractFolderPane, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate {
    // タップした場所によってどう振る舞うべきか
    enum TapCondition :Int {
        case Scroll,
        PageLeft,
        Control,
        PageRight,
        None
    }
    /**
    スクロールする方向
    */
    enum ScrollDirection :Int {
        case Top,
        LeftTop,
        RightTop,
        Left,
        Right,
        Bottom,
        LeftBottom,
        RightBottom,
        None
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    /// シングルタップ
    @IBOutlet var singleTapGr: UITapGestureRecognizer!
    // PageViewControllerを貼り付ける場所
    @IBOutlet weak var containerView: UIView!
    // ControlPane
    var control: ControlPane?
    // 表示する本
    private var _book: Book!
    var book: Book {
        return _book
    }
    // PageViewControllerインスタンス
    private var pvc: UIPageViewController!
    // 現在表示している若い方のページ番号
    var currentPage: Int {
        if (currentPagePane == nil) {
            return 0
        } else {
            return currentPagePane.page
        }
    }
    // 現在表示しているページのページ番号が若い方
    var currentPagePane: BookPagePane! {
        if (folder.isLeftward) {
            return rightPagePane
        } else {
            return leftPagePane
        }
    }
    // 左側のページ
    private var leftPagePane: BookPagePane! {
        var pages = pvc.viewControllers!;
        if (pages.count == 1) {
            return pages[0] as? BookPagePane
        } else if (pages.count == 2) {
            return pages[0] as? BookPagePane
        } else {
            return nil
        }
    }
    // 右側のページ
    private var rightPagePane: BookPagePane! {
        var pages = pvc.viewControllers!;
        if (pages.count == 1) {
            return pages[0] as? BookPagePane
        } else if (pages.count == 2) {
            return pages[1] as? BookPagePane
        } else {
            return nil
        }
    }
    
    
    // MARK: - private
    // UIPageViewControllerを生成する
    private func makeupPageVieController() {
        var loc: UIPageViewControllerSpineLocation
        if (toShowDouble()) {
            loc = .Mid
        } else if (folder.isLeftward) {
            loc = .Max
        } else {
            loc = .Min
        }
        if (pvc != nil && pvc.spineLocation != loc) {
            pvc.delegate = nil
            pvc.dataSource = nil
            pvc.view.removeFromSuperview()
            pvc.removeFromParentViewController()
            pvc = nil
        }
        if (pvc == nil) {
            pvc = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.PageCurl,
                navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal,
                options: [
                    UIPageViewControllerOptionSpineLocationKey: loc.rawValue
                ])
            pvc.delegate = self
            pvc.dataSource = self
            addChildViewController(pvc)
            containerView.addSubview(pvc.view)
            pvc.view.eFitToSuperview()
            for g in pvc.view.gestureRecognizers ?? [] {
                if (g.isKindOfClass(UITapGestureRecognizer)) {
                    pvc.view.removeGestureRecognizer(g )
                }
            }
        }
    }
    
    // 2ページ表示するべきかどうか
    private func toShowDouble() -> Bool {
        if (EG.isForIpad() && EG.isLandscape()) {
            return true
        } else {
            return false
        }
    }
    // 2ページ表示しているかどうか
    private func isShowingDouble() -> Bool {
        return pvc.viewControllers!.count == 2
    }
    // BookPagePaneインスタンスを生成して返す
    private func createPage(page: Int!) -> BookPagePane {
        let p = storyboard?.instantiateViewControllerWithIdentifier("BookPagePane") as! BookPagePane
        p.book = book
        p.page = page
        return p
    }
    // 次のページを返す
    private func nextPage(p:BookPagePane) -> BookPagePane? {
        if (p.page < folder.pageCount) {
            return createPage(p.page + 1)
        } else {
            return nil
        }
    }
    // 前のページを返す
    private func prevPage(p:BookPagePane) -> BookPagePane? {
        if (p.page > 1) {
            return createPage(p.page - 1)
        } else {
            return nil
        }
    }
    
    /**
    指定ページの表示または次の本に遷移する
    - parameter p:        ページ番号
    - parameter animated: アニメーション
    */
    private func showPageOrChangeBook(p:Int, animated:Bool) {
        if (p < 1) {
            goPrev(-1)
            showMessage(eR("Jumped to prev book.") + "\n" + folder.name!)
        } else if (folder.pageCount < p) {
            folder.lastRead = 1
            folder.save()
            goNext(1)
            showMessage(eR("Jumped to next book.") + "\n" + folder.name!)
        } else {
            showPage(p, animated:animated)
            hideMessage()
        }
    }
    /**
    Folderが表示可能かどうかを判定する
    - parameter folder: フォルダ
    - returns: 存在してキャッシュ完了していればtrue
    */
    private func showable(folder:Folder?) -> Bool {
        if (folder != nil) {
            if (!folder!.cacheCompleted) {
                folder!.reload()
            }
            return folder!.isBook && folder!.cacheCompleted
        }
        return false
    }
    
    
    /**
    ページが表示されたときのイベント
    */
    private func pageShown() {
        folder.lastRead = currentPage
        folder.save()
    }
    
    
    /**
    操作画面を開く
    */
    private func showControl() {
        control = showCoverViewController("ControlPane", onView: containerView) as? ControlPane
        setNeedsStatusBarAppearanceUpdate()
    }

    /**
    メッセージを表示する
    - parameter message: メッセージ
    */
    private func showMessage(message:String) {
        messageLabel.text = message
        messageLabel.eFadein()
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC))
        dispatch_after(when, dispatch_get_main_queue()) { () -> Void in
            self.messageLabel.eFadeout()
        }
    }
    /**
    メッセージを非表示にする
    */
    private func hideMessage() {
        messageLabel.eFadeout()
    }

    /**
    タップされた場所を分類する
    - parameter p: タップ位置
    - returns: 場所の分類
    */
    private func calcTapCondition(p: CGPoint) -> (TapCondition, ScrollDirection) {
        let lx = p.x / view.eWidth
        let ly = p.y / view.eHeight
        let rl = leftPagePane.remainLeftScroll
        let rt = leftPagePane.remainTopScroll
        let rr = leftPagePane.remainRightScroll
        let rb = leftPagePane.remainBottomScroll
        var scr:ScrollDirection = .None
        var tap: TapCondition = .Scroll
        if (leftPagePane.isZoomed) {
            if (lx < 0.3) {
                if (ly < 0.3) {
                    if (rl || rt) {
                        scr = .LeftTop
                    } else {
                        tap = .PageLeft
                    }
                } else if (ly < 0.7) {
                    if (rl) {
                        scr = .Left
                    } else {
                        tap = .PageLeft
                    }
                } else {
                    if (rl || rb) {
                        scr = .LeftBottom
                    } else {
                        tap = .PageLeft
                    }
                }
            } else if (lx < 0.7) {
                if (ly < 0.3) {
                    scr = .Top
                } else if (ly < 0.7) {
                    scr = .None
                    tap = .Control
                } else {
                    scr = .Bottom
                }
            } else {
                if (ly < 0.3) {
                    if (rr || rt) {
                        scr = .RightTop
                    } else {
                        tap = .PageRight
                    }
                } else if (ly < 0.7) {
                    if (rr) {
                        scr = .Right
                    } else {
                        tap = .PageRight
                    }
                } else {
                    if (rr || rb) {
                        scr = .RightBottom
                    } else {
                        tap = .PageRight
                    }
                }
            }
            return (tap, scr)
        } else {
            if (lx < 0.25) {
                // 左端
                if (rl) {
                    return (.Scroll, .Left)
                } else {
                    return (.PageLeft, .None)
                }
            } else if (lx > 0.75) {
                // 右端
                if (rr) {
                    return (.Scroll, .Right)
                } else {
                    return (.PageRight, .None)
                }
            } else {
                // 真ん中
                return (.Control, .None)
            }
        }
    }
    
    
    // MARK: - AbstractFolderPane
    
    /**
    folderプロパティが更新された時のイベント
    - parameter f: 新しいfolder
    */
    override func onFolderSet(f: Folder) {
        _book = Book(folder: f)
        f.parentFolder?.lastRead = f.id
        f.parentFolder?.save()
    }
    
    // MARK: - public methods
    
    /**
    フォルダ内の次の本を表示する
    */
    func goNext(page:Int? = nil) {
        let n = folder.nextBookFolder
        if (showable(n)) {
            folder = n
            var p:Int
            if (page == nil) {
                p = folder.lastRead
            } else if (page == -1) {
                p = folder.pageCount
            } else {
                p = page!
            }
            showPage(p, animated: false)
        }
    }
    /**
    フォルダ内の前の本を表示する
    */
    func goPrev(page:Int? = nil) {
        let n = folder.prevBookFolder
        if (showable(n)) {
            folder = n
            var p:Int
            if (page == nil) {
                p = folder.lastRead
            } else if (page == -1) {
                p = folder.pageCount
            } else {
                p = page!
            }
            showPage(p, animated: false)
        }
    }

    
    
    /**
    ページを開く
    - parameter page:     ページ番号
    - parameter animated: アニメーション
    */
    func showPage(page:Int, animated:Bool = false) {
        if (page <= 0 || folder.pageCount < page) {
            return
        }
        var pages: [BookPagePane]
        if (toShowDouble()) {
            // 2ページ表示
            let p1 = createPage(page)
            let p2 = nextPage(p1)
            if (folder.isLeftward) {
                pages = p2 != nil ? [p2!, p1] : [p1]
            } else {
                pages = p2 != nil ? [p1, p2!] : [p1]
            }
            pvc.doubleSided = true
        } else {
            // 1ページ表示
            let p = createPage(page)
            pages = [p]
            pvc.doubleSided = false
        }
        var direction: UIPageViewControllerNavigationDirection
        if ((currentPage < page) == folder.isLeftward) {
            direction = .Reverse
            pages[0].left = false
        } else {
            direction = .Forward
            pages[0].left = true
        }
        pvc.setViewControllers(pages, direction: direction, animated: animated, completion: {completed in
            self.pageShown()
        })
    }
    
    /**
    操作画面を閉じる
    */
    func dismissControl() {
        if (control != nil) {
            let c = control!
            c.dismissCoveringViewController()
            control = nil
        }
    }
    
    // MARK: - Event
    
    /**
    操作画面を閉じた時にステータスバーを消す
    - parameter viewController: 画面
    */
    override func coveredViewControllerWillDismiss(viewController: PaneBase) {
        setNeedsStatusBarAppearanceUpdate()
    }
    
    /**
    ダブルタップイベント
    - parameter gr: ゼスチャー
    */
    @IBAction func longPressed(gr: UILongPressGestureRecognizer) {
        Logger.debug(gr, message: "長押し")
        if (gr.state == .Began) {
            if (leftPagePane.isZoomed) {
                leftPagePane.zoomDown()
            } else {
                var p = gr.locationOfTouch(0, inView: view)
                p.x /= view.eWidth
                p.y /= view.eHeight
                leftPagePane.zoomUp(p)
            }
        }
    }
    
    /**
    タップイベント
    - parameter gr: ゼスチャー
    */
    @IBAction func tapped(gr: UITapGestureRecognizer) {
        let (tap, scroll) = calcTapCondition(gr.locationOfTouch(0, inView: view))
        switch (tap) {
        case .Control:
            showControl()
        case .Scroll:
            leftPagePane.scrollTo(scroll, animated: true)
        case .PageLeft:
            pageLeft(true)
        case .PageRight:
            pageRight(true)
        default:
            break
        }
        gr.cancelsTouchesInView = true
    }
    /**
    左方向のページめくり
    - parameter animated: アニメーション
    */
    func pageLeft(animated:Bool) {
        var p = currentPage
        let delta = isShowingDouble() ? 2 : 1
        if (folder.isLeftward) {
            p += delta
        } else {
            p -= delta
        }
        showPageOrChangeBook(p, animated: animated)
    }
    /**
    右方向のページめくり
    - parameter animated: アニメーション
    */
    func pageRight(animated:Bool) {
        var p = currentPage
        let delta = isShowingDouble() ? 2 : 1
        if (folder.isLeftward) {
            p -= delta
        } else {
            p += delta
        }
        showPageOrChangeBook(p, animated: animated)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    /**
    操作画面表示中はゼスチャーを無視する
    - parameter gestureRecognizer: ゼスチャー
    - returns: 操作画面表示中はfalse
    */
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (control == nil)
    }
//    /**
//    タップ位置によってシングルタップの扱いを判定する
//    
//    :param: gr    ゼスチャー
//    :param: touch タップ位置
//    
//    :returns: <#return value description#>
//    */
//    func gestureRecognizer(gr: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
//        var condition = calcTapCondition(touch.locationInView(view))
//        switch (condition) {
//        case .Control, .ScrollLeft, .ScrollRight:
//            return true
//        default:
//            return true
//        }
//    }
    
    // MARK: - PaneBase
    
    
    // MARK: - UIViewController
    
    /**
    View初期化
    */
    override func viewDidLoad() {
    }
    
    /**
    view表示直前
    - parameter animated: アニメーション
    */
    override func viewWillAppear(animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        makeupPageVieController()
        showPage(folder.lastRead)
    }
    /**
    view表示
    - parameter animated: アニメーション
    */
    override func viewDidAppear(animated: Bool) {
        
    }
    /**
    ステータスバー非表示
    - returns: Control表示中は表示
    */
    override func prefersStatusBarHidden() -> Bool {
        return control == nil
    }
    /**
    ステータスバー処理
    - returns: Fade
    */
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    /**
    ステータスバースタイル
    - returns: Light
    */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    
    /**
    前のページを返す
    - parameter pageViewController: pv
    - parameter viewController:     現在
    - returns: 前のページ
    */
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerBeforeViewController viewController: UIViewController)
        -> UIViewController?
    {
        let p = viewController as! BookPagePane
        return folder.isLeftward ? nextPage(p) : prevPage(p)
    }
    
    /**
    次のページを返す
    - parameter pageViewController: pv
    - parameter viewController:     現在
    - returns: 次のページ
    */
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerAfterViewController viewController: UIViewController)
        -> UIViewController?
    {
        let p = viewController as! BookPagePane
        return folder.isLeftward ? prevPage(p) : nextPage(p)
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    /**
    ページめくり直後イベント
    - parameter pageViewController:      pv
    - parameter finished:                アニメーション終わったかどうか
    - parameter previousViewControllers: 前のページ
    - parameter completed:               終わったかどうか
    */
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (completed) {
            pageShown()
        }
    }

}
