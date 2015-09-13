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
    private let minimumSize:CGSize
    
    init(folder:Folder) {
        self.folder = folder
        let ms = UIScreen.mainScreen()
        let sz = ms.bounds.size
        let sc = ms.scale * 2
        minimumSize = CGSize(width: sz.width * sc, height: sz.height * sc)

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
            let rect:CGRect = CGPDFPageGetBoxRect(page, CGPDFBox.TrimBox)
            let origSize = rect.size
            let size:CGSize
            let scale:CGFloat
            if (origSize.width < minimumSize.width && origSize.height < minimumSize.height) {
                scale = max(minimumSize.width / origSize.width, minimumSize.height / origSize.height)
                size = CGSizeMake(origSize.width * scale, origSize.height * scale)
            } else {
                scale = 1
                size = origSize
            }
            
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()
            // 反転する
            CGContextTranslateCTM(context, 0, size.height);
            CGContextScaleCTM(context, scale, -scale);
            CGContextSaveGState(context);
            
            // UIImageに書き出す
            CGContextDrawPDFPage(context, page);
            
            
            let image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext()
            
            // JPEGファイルに書き出す
            let data = UIImageJPEGRepresentation(image, 0.9)
            let dstPath = folder.realPath!.eAddPath(String(format: "%05d", pageNum))
            result = data!.writeToFile(dstPath, atomically: true)
        }
        return result
    }
   
}
