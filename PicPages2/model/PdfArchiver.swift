//
//  PdfArchiver.swift
//  PicPages
//
//  Created by 藤田正訓 on 2015/07/22.
//  Copyright (c) 2015年 tkr. All rights reserved.
//

import UIKit
/// PDFをページ分解するクラス
class PdfArchiver: Archiver {
    private let folder:Folder
    private var prevSize:CGSize = CGSizeMake(0, 0)
    
    init(folder:Folder) {
        self.folder = folder
    }
    /**
    アーカイブを展開する
    */
    override func extract() -> Bool {
        let filePath = folder.realPath!.eAddPath(folder.originalName!)
        let fileUrl = NSURL(fileURLWithPath: filePath)
        let doc = CGPDFDocumentCreateWithURL(fileUrl)
        let pageCount = CGPDFDocumentGetNumberOfPages(doc)
        folder.pageCount = pageCount
        if (pageCount >= 1) {
            for var p = 1; p <= pageCount; p++ {
                if (!extractPage(doc!, pageNum: p)) {
                    break;
                }
            }
            UIGraphicsEndImageContext()
        }
        folder.cacheCompleted = true
        folder.save()
        FileUtil.rm(filePath)
        return true
    }
    
    /**
    1ページを展開する
    - parameter doc:  PDFファイル
    - parameter page: ページ番号
    */
    private func extractPage(doc:CGPDFDocumentRef, pageNum:Int) -> Bool {
        var result:Bool = false
        autoreleasepool { () -> () in
            let page = CGPDFDocumentGetPage(doc, pageNum)
            let rect:CGRect = CGPDFPageGetBoxRect(page, CGPDFBox.TrimBox);
            let size:CGSize = rect.size
            if (size.width != prevSize.width || size.height != prevSize.height) {
                if (prevSize.width > 0) {
                    UIGraphicsEndImageContext()
                }
                UIGraphicsBeginImageContext(size)
                let context = UIGraphicsGetCurrentContext()
                // 反転する
                CGContextTranslateCTM(context, 0, size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextSaveGState(context);
                
                prevSize = size
            }
            let context = UIGraphicsGetCurrentContext()
            
            // UIImageに書き出す
            CGContextDrawPDFPage(context, page);
            let image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
            
            // JPEGファイルに書き出す
            let data = UIImageJPEGRepresentation(image, 0.9)
            let dstPath = folder.realPath!.eAddPath(String(format: "%05d", pageNum))
            result = data!.writeToFile(dstPath, atomically: true)
        }
        return result
    }
   
}
