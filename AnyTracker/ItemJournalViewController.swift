//
//  ItemJournalViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 07/10/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemJournalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NotifyItemUpdate, CellKeyboardEvent {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var entriesTableView: UITableView!
    
    var activeView: UIView?
    
    var itemChangeDelegate: ItemChangeDelegate?
    
    var item: ItemJournal!
    var longDateFormat: Bool = true
    var valueDate: Date!
    var keyboardVisible: Bool = false
    var shownKeyboardHeight: CGFloat = 0
    
    var viewOffset: CGFloat = 0
    var keyboardAnimationDuration: Double = App.Constants.Animations.keyboardDuration
    var keyboardAnimationCurve: UIViewAnimationCurve = App.Constants.Animations.keyboardCurve
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        entriesTableView.estimatedRowHeight = 84
        entriesTableView.rowHeight = UITableViewAutomaticDimension
        
        title = item.name
        valueDate = Date()
        valueTextField.text = Utils.stringFrom(date: valueDate, longFormat: longDateFormat)
        
        addButton.disable()
        
        entriesTableView.delegate = self
        entriesTableView.dataSource = self
        entriesTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        nameTextField.delegate = self
        valueTextField.delegate = self
        Utils.addDoneButton(toDateTextField: valueTextField, forTarget: view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ItemJournalViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ItemJournalViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    func keyboardWillShow(_ notification: Notification) {
        keyboardVisible = true
        
        var keyboardHeight: CGFloat = 0
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
        
        var viewHeight = view.frame.size.height
        if viewOffset == 0 {
            shownKeyboardHeight = keyboardHeight
            viewHeight -= keyboardHeight
        } else if shownKeyboardHeight == keyboardHeight {
            return
        } else {
            let diff = shownKeyboardHeight - keyboardHeight
            view.frame.size.height += diff
            shownKeyboardHeight = keyboardHeight
            return
        }
        
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? App.Constants.Animations.keyboardDuration
        keyboardAnimationCurve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? App.Constants.Animations.keyboardCurve.rawValue)!
        
        guard activeView != nil else {
            return
        }
        let activeControlRect: CGRect = activeView!.frame
        var lastVisiblePoint: CGPoint = CGPoint(x: activeControlRect.origin.x, y: activeControlRect.origin.y + activeControlRect.height + App.Constants.Animations.keyboardDistanceToControl)
        if activeView != nameTextField && activeView != valueTextField {
            lastVisiblePoint = activeView!.convert(lastVisiblePoint, to: view)
        }
        
        if lastVisiblePoint.y > viewHeight {
            viewOffset = lastVisiblePoint.y - viewHeight
            if viewOffset > keyboardHeight {
                viewOffset = keyboardHeight
            }
            adaptView(moveUp: true)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        keyboardVisible = false
        
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
        activeView = textField.textInputView
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeView = nil
    }
    
    // MARK: - CellKeyboardEvent
    func willBeginEditing(fromView view: UIView) {
        activeView = view
    }
    
    func willEndEditing(fromView view: UIView) {
        activeView = nil
    }
    
    // MARK: - Actions
    @IBAction func addPressed(_ sender: UIButton) {
        let entry = Entry(name: nameTextField.text!, value: valueDate)
        do {
            try item.insert(entry: entry)
            itemChangeDelegate?.itemChanged()
        } catch let error as Status {
            let alert = error.createErrorAlert()
            self.present(alert, animated: true, completion: nil)
            return
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        entriesTableView.beginUpdates()
        entriesTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.right)
        entriesTableView.endUpdates()
    }
    
    @IBAction func nameChanged(_ sender: UITextField) {
        if nameTextField.text!.isEmpty {
            addButton.disable()
        } else {
            addButton.enable()
        }
    }
    
    func datePickerValueChange(_ sender: UIDatePicker) {
        valueDate = sender.date
        let dateString = Utils.stringFrom(date: sender.date, longFormat: longDateFormat)
        valueTextField.text = dateString
    }
    
    @IBAction func valueDateEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = UIColor.white
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.date = valueDate
        
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChange), for: UIControlEvents.valueChanged)
    }

    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = entriesTableView.dequeueReusableCell(withIdentifier: "ItemJournalCell", for: indexPath) as! ItemJournalCell
        
        cell.viewController = self
        cell.delegate = self
        cell.initCell(withItem: item, andEntryIndex: (indexPath as NSIndexPath).row, longDateFormat: longDateFormat)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if keyboardVisible {
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            do {
                try item.remove(atIndex: (indexPath as NSIndexPath).row)
                itemChangeDelegate?.itemChanged()
            } catch let error as Status {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
