//
//  NewItemViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 27/06/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

protocol NewItemDelegate: class {
    func newItem(_ item : Item, atIndex index: Int, sender: NewItemViewController)
}

protocol EditItemDelegate: class {
    func updateItem(fromSender sender: NewItemViewController)
}

class NewItemViewController: UIViewController {

    weak var delegateNew: NewItemDelegate?
    weak var delegateEdit: EditItemDelegate?
    
    @IBOutlet weak var createBarButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var dateRangeView: UIView!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var simpleKeyboard: SimpleKeyboard?
    
    var list: List!
    var longDateFormat: Bool!
    var insertItemAtFront: Bool!
    
    var editItem: Item?
    
    var startDateEditing = false
    
    var startDate: Date!
    var endDate: Date!
    
    lazy var minMaxDate: (Date, Date) = {
        var minDateComponents = DateComponents()
        minDateComponents.year = 2006
        (minDateComponents as NSDateComponents).timeZone = TimeZone(secondsFromGMT: 0)
        var maxDateComponents = DateComponents()
        maxDateComponents.year = 2046
        maxDateComponents.month = 12
        maxDateComponents.day = 31
        (maxDateComponents as NSDateComponents).timeZone = TimeZone(secondsFromGMT: 0)
        
        let calendar = Calendar.current
        return (calendar.date(from: minDateComponents)!, calendar.date(from: maxDateComponents)!)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Color the segmented control
        let views = typeControl.subviews
        views[ItemType.numberOfItems() - 1 - ItemType.sum.getTypeIndex()].tintColor = Constants.Colors.ItemSum
        views[ItemType.numberOfItems() - 1 - ItemType.counter.getTypeIndex()].tintColor = Constants.Colors.ItemCounter
        views[ItemType.numberOfItems() - 1 - ItemType.journal.getTypeIndex()].tintColor = Constants.Colors.ItemJournal
        
        if let item = editItem {
            createBarButton.isEnabled = true
            typeControl.isEnabled = false
            
            nameTextField.text = item.name
            descriptionTextField.text = item.description
            if item.type == ItemType.counter {
                typeControl.selectedSegmentIndex = 1
            } else if item.type == ItemType.journal {
                typeControl.selectedSegmentIndex = 2
            }
            dateSwitch.isOn = item.useDate
            startDate = item.startDate as Date!
            endDate = item.endDate as Date!
            
            if dateSwitch.isOn {
                startDateTextField.isEnabled = true
                endDateTextField.isEnabled = true
            }
        } else {
            startDate = Date()
            var dateComponents = DateComponents()
            dateComponents.day = 7
            endDate = (Calendar.current as NSCalendar).date(byAdding: dateComponents, to: startDate, options: [])
            
            //nameTextField.becomeFirstResponder()
        }
        
        startDateTextField.text = Utils.stringFrom(date: startDate, startDate: true, longFormat: longDateFormat)
        endDateTextField.text = Utils.stringFrom(date: endDate, startDate: false, longFormat: longDateFormat)
        
        simpleKeyboard = SimpleKeyboard.createKeyboard(forControls: [nameTextField, descriptionTextField], fromViewController: self)
        simpleKeyboard?.add(control: startDateTextField, withDoneButtonKeyboard: true)
        simpleKeyboard?.add(control: endDateTextField, withDoneButtonKeyboard: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let keyboard = simpleKeyboard {
            keyboard.enable()
            
            keyboard.textFieldShouldReturn = { textField in
                textField.resignFirstResponder()
                
                return true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        simpleKeyboard?.disable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareForDismissingController() {
        if nameTextField.isFirstResponder {
            nameTextField.resignFirstResponder()
        } else if descriptionTextField.isFirstResponder {
            descriptionTextField.resignFirstResponder()
        } else if startDateTextField.isFirstResponder {
            startDateTextField.resignFirstResponder()
        } else if endDateTextField.isFirstResponder {
            endDateTextField.resignFirstResponder()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func createItemPressed(_ sender: AnyObject) {
        if let item = editItem {
            do {
                let itemChanged = try item.updateWith(newName: nameTextField.text!, newDescription: descriptionTextField.text ?? "", newUseDate: dateSwitch.isOn, newStartDate: startDate, newEndDate: endDate)
            
                if delegateEdit != nil && itemChanged {
                    delegateEdit!.updateItem(fromSender: self)
                }
            } catch let error as Status {
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.errorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            }
        } else {
            var item: Item?
            var itemSaved = false
            var insertIndex = -1
            do {
                item = try Items.createItem(withName: nameTextField.text!, description: descriptionTextField.text ?? "", type: typeControl.selectedSegmentIndex == 0 ? ItemType.sum : typeControl.selectedSegmentIndex == 1 ? ItemType.counter : ItemType.journal, useDate: dateSwitch.isOn, startDate: startDate, endDate: endDate)
                try item!.saveToFile()
                itemSaved = true
                insertIndex = try list.insert(item: item!, atFront: insertItemAtFront)
            } catch let error as Status {
                if itemSaved {
                    let _ = Items.deleteItemFile(withID: item!.ID)
                }
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.errorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            }
            
            if delegateNew != nil {
                delegateNew!.newItem(item!, atIndex: insertIndex, sender: self)
            }
        }
    
        prepareForDismissingController()
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func itemNameChanged(_ sender: UITextField) {
        let count = nameTextField.text?.characters.count ?? 0
        if count > 0 {
            createBarButton.isEnabled = true
        } else {
            createBarButton.isEnabled = false
        }
    }
    
    @IBAction func dateSwitchChanged(_ sender: AnyObject) {
        if dateSwitch.isOn {
            startDateTextField.isEnabled = true
            endDateTextField.isEnabled = true
        } else {
            startDateTextField.isEnabled = false
            endDateTextField.isEnabled = false
        }
    }
    
    func datePickerValueChange(_ sender: UIDatePicker) {
        let dateString = Utils.stringFrom(date: sender.date, startDate: startDateEditing, longFormat: longDateFormat)
        if startDateEditing {
            startDate = sender.date
            startDateTextField.text = dateString
        } else {
            endDate = sender.date
            endDateTextField.text = dateString
        }
    }
    
    @IBAction func startDateEditing(_ sender: UITextField) {
        startDateEditing = true
        
        let (minDate, _) = minMaxDate
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = UIColor.white
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.minimumDate = minDate
        datePickerView.maximumDate = endDate
        datePickerView.date = startDate
        
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChange), for: UIControlEvents.valueChanged)
    }
    
    @IBAction func endDateEditing(_ sender: UITextField) {
        startDateEditing = false
        
        let (_, maxDate) = minMaxDate
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = UIColor.white
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.minimumDate = startDate
        datePickerView.maximumDate = maxDate
        datePickerView.date = endDate
        
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChange), for: UIControlEvents.valueChanged)
    }
}
