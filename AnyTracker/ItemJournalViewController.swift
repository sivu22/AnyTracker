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
    
    var simpleKeyboard: SimpleKeyboard!
    
    var itemChangeDelegate: ItemChangeDelegate?
    
    var item: ItemJournal!
    var longDateFormat: Bool = true
    var valueDate: Date!
    var keyboardVisible: Bool = false
    var shownKeyboardHeight: CGFloat = 0
    
    var viewOffset: CGFloat = 0
    var keyboardAnimationDuration: Double = Constants.Animations.keyboardDuration
    var keyboardAnimationCurve: UIViewAnimationCurve = Constants.Animations.keyboardCurve
    
    
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
        
        simpleKeyboard = SimpleKeyboard.createKeyboard(forControls: [nameTextField], fromViewController: self)
        simpleKeyboard.add(control: valueTextField, withDoneButtonKeyboard: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        simpleKeyboard.enable()
        
        simpleKeyboard.textFieldShouldReturn = { textField in
            textField.resignFirstResponder()
            
            return true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        simpleKeyboard.disable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CellKeyboardEvent
    
    func willBeginEditing(fromView view: UIView) {
        simpleKeyboard.setActive(view: view)
    }
    
    func willEndEditing(fromView view: UIView) {
        simpleKeyboard.clearActiveView()
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
