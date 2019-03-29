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
    var keyboardAnimationCurve: UIView.AnimationCurve = Constants.Animations.keyboardCurve
    
    var reorderTableView: LongPressReorderTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        entriesTableView.estimatedRowHeight = 84
        entriesTableView.rowHeight = UITableView.automaticDimension
        
        title = item.name
        valueDate = Date()
        valueTextField.text = Utils.stringFrom(date: valueDate, longFormat: longDateFormat)
        
        addButton.disable()
        
        entriesTableView.delegate = self
        entriesTableView.dataSource = self
        entriesTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        simpleKeyboard = SimpleKeyboard.createKeyboard(forControls: [nameTextField], fromViewController: self)
        simpleKeyboard.add(control: valueTextField, withDoneButtonKeyboard: true)
        
        reorderTableView = LongPressReorderTableView(entriesTableView)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
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
        item.insert(entry: entry) { error in
            if let error = error {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            //Utils.debugLog("Successfully added entry of Journal item \(self.item.ID)")
            
            self.itemChangeDelegate?.itemChanged()
            self.entriesTableView.beginUpdates()
            self.entriesTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableView.RowAnimation.right)
            self.entriesTableView.endUpdates()
        }
    }
    
    @IBAction func nameChanged(_ sender: UITextField) {
        if nameTextField.text!.isEmpty {
            addButton.disable()
        } else {
            addButton.enable()
        }
    }
    
    @objc func datePickerValueChange(_ sender: UIDatePicker) {
        valueDate = sender.date
        let dateString = Utils.stringFrom(date: sender.date, longFormat: longDateFormat)
        valueTextField.text = dateString
    }
    
    @IBAction func valueDateEditing(_ sender: UITextField) {
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = UIColor.white
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        datePickerView.date = valueDate
        
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChange), for: UIControl.Event.valueChanged)
    }

    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = entriesTableView.dequeueReusableCell(withIdentifier: "ItemJournalCell", for: indexPath) as! ItemJournalCell
        
        cell.viewController = self
        cell.delegate = self
        cell.initCell(withItem: item, andEntryIndex: indexPath.row, longDateFormat: longDateFormat)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if keyboardVisible {
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            item.remove(atIndex: indexPath.row) { error in
                if let error = error {
                    let alert = error.createErrorAlert()
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
                
                //Utils.debugLog("Successfully removed entry of Journal item \(self.item.ID)")
                
                self.itemChangeDelegate?.itemChanged()
                CATransaction.begin()
                CATransaction.setCompletionBlock({() in tableView.reloadData() })
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
                CATransaction.commit()
            }
        }
    }
}

// MARK: - Long press drag and drop reorder

extension ItemJournalViewController {
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        item.exchangeEntry(fromIndex: currentIndex.row, toIndex: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        DispatchQueue.global().async {
            do {
                try self.item.saveToFile()
            } catch let error as Status {
                DispatchQueue.main.async {
                    let alert = error.createErrorAlert()
                    self.present(alert, animated: true, completion: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = Status.errorDefault.createErrorAlert()
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

