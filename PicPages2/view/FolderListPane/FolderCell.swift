//
//  FolderCell.swift
//  PicPages
//
//  Created by 藤田正訓 on 2014/12/06.
//  Copyright (c) 2014年 tkr. All rights reserved.
//

import UIKit

class FolderCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var lockIcon: UIImageView!
    
    weak var folder: Folder?
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
