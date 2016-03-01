//
//  DogTableViewCell.swift
//  Inugress
//
//  Created by PCUser on 2/15/16.
//  Copyright © 2016 Haoxiang Li. All rights reserved.
//

import UIKit

class DogTableViewCell: UITableViewCell {

    @IBOutlet var labelA: UILabel!
    @IBOutlet var dogImageView: UIImageView!
    @IBOutlet var probLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        labelA.numberOfLines = 0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
