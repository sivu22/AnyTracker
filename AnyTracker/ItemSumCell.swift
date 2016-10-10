//
//  ItemSumCell.swift
//  AnyTracker
//
//  Created by Cristian Sava on 28/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemSumCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    
    var viewController: ItemSumViewController?
    var delegate: CellKeyboardEvent?
    
    fileprivate var item: ItemSum!
    fileprivate var elementIndex = -1
    fileprivate var numberSeparator: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initCell(withItem item: ItemSum, andElementIndex index: Int, showSeparator separator: Bool) {
        self.item = item
        elementIndex = index
        numberSeparator = separator
        
        if !item.elements[index].name.isEmpty {
            nameTextField.text = item.elements[index].name
        } else {
            nameTextField.text = ""
            nameTextField.placeholder = "Description"
        }
        valueTextField.text = item.elements[index].value.asString(withSeparator: numberSeparator)
        
        nameTextField.delegate = self
        valueTextField.delegate = self
        Utils.addDoneButton(toTextField: valueTextField, forTarget: self.contentView, negativeTarget: self, negativeSelector: #selector(ItemSumCell.negativePressed))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        do {
            try item.updateElement(atIndex: elementIndex, newName: textField.text!, newValue: item.elements[elementIndex].value)
        } catch let error as Status {
            let alert = error.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
            return true
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
            return true
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.willBeginEditing(fromView: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.willEndEditing(fromView: textField)
    }
    
    @IBAction func valueEditBegin(_ sender: UITextField) {
        sender.text = item.elements[elementIndex].value.asString()
    }
    
    @IBAction func valueEditEnd(_ sender: UITextField) {
        var newValue: Double = 0
        var valueText = sender.text!
        if !valueText.isEmpty {
            if valueText == "-0" {
                sender.text = "0"
            }
            
            valueText = valueText.replacingOccurrences(of: ",", with: ".")
            let value = Double(valueText)
            if value != nil {
                newValue = value!
            } else {
                sender.text = "0"
            }
        } else {
            sender.text = "0"
        }
        
        do {
            try item.updateElement(atIndex: elementIndex, newName: item.elements[elementIndex].name, newValue: newValue)
            valueTextField.text = item.elements[elementIndex].value.asString(withSeparator: numberSeparator)
        } catch let error as Status {
            let alert = error.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            viewController?.present(alert, animated: true, completion: nil)
        }
        
        viewController?.sumLabel.text = item.sum.asString(withSeparator: numberSeparator)
        viewController?.itemChangeDelegate?.itemChanged()
    }
    
    func negativePressed() {
        let valueText = valueTextField.text!
        if valueText.characters.first == "-" {
            valueTextField.text = String(valueText.characters.dropFirst())
        } else {
            valueTextField.text = "-" + valueText
        }
    }
}