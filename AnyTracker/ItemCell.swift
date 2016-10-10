//
//  ItemCell.swift
//  AnyTracker
//
//  Created by Cristian Sava on 24/06/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var datesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initCell(withItem item: Item, separator: Bool, longFormat: Bool) {
        nameLabel.text = item.name
        descriptionLabel.text = item.description
        if descriptionLabel.text == "" {
            for constraint in self.contentView.constraints {
                if constraint.identifier == "descriptionToValue" {
                    constraint.constant = 0
                }
            }
        }
        if item.useDate {
            datesLabel.text = Utils.stringFrom(date: item.startDate, longFormat: longFormat) + " - " + Utils.stringFrom(date: item.endDate, longFormat: longFormat)
        } else {
            datesLabel.text = ""
            for constraint in self.contentView.constraints {
                if constraint.identifier == "dateToDescription" {
                    constraint.constant = 0
                }
            }
        }
        
        if let sumItem = item as? ItemSum {
            typeLabel.backgroundColor = App.Constants.Colors.ItemSum
            valueLabel.text = sumItem.sum.asString(withSeparator: separator)
        } else if let counterItem = item as? ItemCounter {
            typeLabel.backgroundColor = App.Constants.Colors.ItemCounter
            valueLabel.text = counterItem.counter.asString(withSeparator: separator)
        } else if let journalItem = item as? ItemJournal {
            typeLabel.backgroundColor = App.Constants.Colors.ItemJournal
            valueLabel.text = journalItem.entries.count == 0 ? "No entries" : journalItem.entries.count == 1 ? "1 entry" : "\(journalItem.entries.count) entries"
        }
    }

}
