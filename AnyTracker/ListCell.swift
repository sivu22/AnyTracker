//
//  ListCell.swift
//  AnyTracker
//
//  Created by Cristian Sava on 03/03/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var itemsLabel: UILabel!
    
    func initCellWithName(_ name: String, andItems items: Int) {
        nameLabel.text = name
        itemsLabel.text = String(items) + Constants.Text.listItems
    }
}
