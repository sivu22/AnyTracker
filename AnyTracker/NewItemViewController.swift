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

class NewItemViewController: UIViewController, UITextFieldDelegate {

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
    var activeView: UIView?
    
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
    
    var viewOffset: CGFloat = 0
    var keyboardAnimationDuration: Double = Constants.Animations.keyboardDuration
    var keyboardAnimationCurve: UIViewAnimationCurve = Constants.Animations.keyboardCurve

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        descriptionTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
        
        // Hide the cursor
        startDateTextField.tintColor = UIColor.clear
        endDateTextField.tintColor = UIColor.clear
        
        // Color the segmented control
        let views = typeControl.subviews
        views[ItemType.numberOfItems() - 1 - ItemType.Sum.getTypeIndex()].tintColor = Constants.Colors.ItemSum
        views[ItemType.numberOfItems() - 1 - ItemType.Counter.getTypeIndex()].tintColor = Constants.Colors.ItemCounter
        views[ItemType.numberOfItems() - 1 - ItemType.Journal.getTypeIndex()].tintColor = Constants.Colors.ItemJournal
        
        if let item = editItem {
            createBarButton.isEnabled = true
            typeControl.isEnabled = false
            
            nameTextField.text = item.name
            descriptionTextField.text = item.description
            if item.type == ItemType.Counter {
                typeControl.selectedSegmentIndex = 1
            } else if item.type == ItemType.Journal {
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
        
        Utils.addDoneButton(toDateTextField: startDateTextField, forTarget: view)
        Utils.addDoneButton(toDateTextField: endDateTextField, forTarget: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewItemViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewItemViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adaptView(moveUp: Bool)
    {
        var movementDistance: CGFloat = -viewOffset
        let movementDuration: Double = keyboardAnimationDuration
        
        if !moveUp {
            movementDistance = -movementDistance
        }
        
        UIView.beginAnimations("adaptView", context: nil)
        UIView.setAnimationCurve(keyboardAnimationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        view.frame = view.frame.offsetBy(dx: 0, dy: movementDistance)
        UIView.commitAnimations()
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        var keyboardHeight: CGFloat = 0
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
        
        var viewHeight = view.frame.size.height
        if viewOffset == 0 {
            viewHeight -= keyboardHeight
        } else {
            return
        }
        
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? Constants.Animations.keyboardDuration
        keyboardAnimationCurve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? Constants.Animations.keyboardCurve.rawValue)!
        
        let activeTextFieldRect: CGRect = activeView!.frame
        var lastVisiblePoint: CGPoint = CGPoint(x: activeTextFieldRect.origin.x, y: activeTextFieldRect.origin.y + activeTextFieldRect.height + Constants.Animations.keyboardDistanceToControl)
        if activeView == startDateTextField || activeView == endDateTextField {
            lastVisiblePoint = CGPoint(x: lastVisiblePoint.x + dateRangeView.frame.origin.x, y: lastVisiblePoint.y + dateRangeView.frame.origin.y)
        }
        
        if lastVisiblePoint.y > viewHeight {
            viewOffset = lastVisiblePoint.y - viewHeight
            if viewOffset > keyboardHeight {
                viewOffset = keyboardHeight
            }
            adaptView(moveUp: true)
        }
    }
    
    func keyboardWillHide(_ notification: NSNotification) {
        if viewOffset != 0 {
            adaptView(moveUp: false)
            viewOffset = 0
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeView = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeView = nil
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
                let alert = Status.ErrorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            }
        } else {
            var item: Item?
            var itemSaved = false
            var insertIndex = -1
            do {
                item = try Items.createItem(withName: nameTextField.text!, description: descriptionTextField.text ?? "", type: typeControl.selectedSegmentIndex == 0 ? ItemType.Sum : typeControl.selectedSegmentIndex == 1 ? ItemType.Counter : ItemType.Journal, useDate: dateSwitch.isOn, startDate: startDate, endDate: endDate)
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
                let alert = Status.ErrorDefault.createErrorAlert()
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
