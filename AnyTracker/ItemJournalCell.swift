//
//  ItemJournalCell.swift
//  AnyTracker
//
//  Created by Cristian Sava on 08/10/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemJournalCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var nameTextView: UITextView!
    @IBOutlet weak var valueTextField: UITextField!
    
    var viewController: ItemJournalViewController?
    var delegate: CellKeyboardEvent?
    
    fileprivate var item: ItemJournal!
    fileprivate var entryIndex = -1
    fileprivate var longDateFormat = true
    var valueDate: Date!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initCell(withItem item: ItemJournal, andEntryIndex index: Int, longDateFormat dateFormat: Bool) {
        self.item = item
        entryIndex = index
        longDateFormat = dateFormat
        
        nameTextView.text = item.entries[index].name
        valueDate = item.entries[index].value
        valueTextField.text = Utils.stringFrom(date: valueDate, longFormat: longDateFormat)
        
        valueTextField.delegate = self
        Utils.addDoneButton(toDateTextField: valueTextField, forTarget: self, doneSelector: #selector(ItemJournalCell.donePressed))
        nameTextView.delegate = self
        Utils.addDoneButton(toTextView: nameTextView, forTarget: self, doneSelector: #selector(ItemJournalCell.donePressed))
    }
    
    func donePressed() {
        if valueTextField.isFirstResponder {
            valueTextField.resignFirstResponder()
        } else {
            nameTextView.resignFirstResponder()
        }
        
        if nameTextView.text == item.entries[entryIndex].name && valueDate == item.entries[entryIndex].value {
            return
        }
        
        do {
            try item.updateEntry(atIndex: entryIndex, newName: nameTextView.text!, newValue: valueDate)
        } catch let error as Status {
            let alert = error.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.willBeginEditing(fromView: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.willEndEditing(fromView: textField)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.willBeginEditing(fromView: textView)
        textView.isScrollEnabled = true
        
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        delegate?.willEndEditing(fromView: textView)
        textView.isScrollEnabled = false
        viewController!.entriesTableView.beginUpdates()
        textView.frame = CGRect(origin: CGPoint(x: textView.frame.minX, y: textView.frame.minY), size: CGSize(width: textView.frame.width, height: textView.contentSize.height))
        viewController!.entriesTableView.endUpdates()
        
        return true
    }
    
    func datePickerValueChange(_ sender: UIDatePicker) {
        valueDate = sender.date
        let dateString = Utils.stringFrom(date: sender.date, longFormat: longDateFormat)
        valueTextField.text = dateString
    }

    // MARK: - Actions
    @IBAction func valueDateEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = UIColor.white
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.date = valueDate
        
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChange), for: UIControlEvents.valueChanged)
    }
}
