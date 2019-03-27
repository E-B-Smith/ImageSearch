//
//  ISImageTableViewCell.swift
//  ImageSearch
//
//  Created by Edward Smith on 3/22/19.
//  Copyright © 2019 Edward Smith. All rights reserved.
//

import UIKit

class ISImageTableViewCell : UITableViewCell {
    static let reuseID = "ISImageTableViewCell"
    static let height:CGFloat = 180.0
    
    @IBOutlet var largeImageView: UIImageView!
    @IBOutlet var debugLabel: UILabel!
}
