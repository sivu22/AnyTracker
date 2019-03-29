//
//  ItemSumViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 27/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemSumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NotifyItemUpdate, CellKeyboardEvent {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var sumLabel: UILabel!
    @IBOutlet weak var elementsTableView: UITableView!
    
    var simpleKeyboard: SimpleKeyboard!
    
    var itemChangeDelegate: ItemChangeDelegate?
    
    var item: ItemSum!
    var numberSeparator: Bool = false
    var keyboardVisible: Bool = false
    var shownKeyboardHeight: CGFloat = 0
    
    var viewOffset: CGFloat = 0
    var keyboardAnimationDuration: Double = Constants.Animations.keyboardDuration
    var keyboardAnimationCurve: UIView.AnimationCurve = Constants.Animations.keyboardCurve
    
    var reorderTableView: LongPressReorderTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = item.name
        
        addButton.disable()
        sumLabel.text = item.sum.asString(withSeparator: numberSeparator)
        
        elementsTableView.delegate = self
        elementsTableView.dataSource = self
        elementsTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        simpleKeyboard = SimpleKeyboard(fromViewController: self)
        simpleKeyboard.add(control: nameTextField)
        simpleKeyboard.add(control: valueTextField)
        Utils.addDoneButton(toTextField: valueTextField, forTarget: view, negativeTarget: self, negativeSelector: #selector(ItemSumViewController.negativePressed))
        
        reorderTableView = LongPressReorderTableView(elementsTableView, selectedRowScale: SelectedRowScale.small)
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
    
    @IBAction func addPressed(_ sender: AnyObject) {
        let correctString = valueTextField.text!.replacingOccurrences(of: ",", with: ".")
        let element = Element(name: nameTextField.text!, value: Double(correctString)!)
        
        item.insert(element: element) { error in
            if let error = error {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            //Utils.debugLog("Successfully added element of Sum item \(self.item.ID)")
            
            self.itemChangeDelegate?.itemChanged()
            
            self.sumLabel.text = self.item.sum.asString(withSeparator: self.numberSeparator)
            self.elementsTableView.beginUpdates()
            self.elementsTableView.insertRows(at: [IndexPath(row: self.item.elements.count - 1, section: 0)], with: UITableView.RowAnimation.right)
            self.elementsTableView.endUpdates()
        }
    }
    
    @IBAction func valueChanged(_ sender: AnyObject) {
        if valueTextField.text!.isEmpty {
            addButton.disable()
        } else {
            let valueText = valueTextField.text!.replacingOccurrences(of: ",", with: ".")
            let value = Double(valueText)
            if value != nil {
                addButton.enable()
            } else {
                addButton.disable()
            }
        }
    }
    
    @objc func negativePressed() {
        let valueText = valueTextField.text!
        if valueText.first == "-" {
            valueTextField.text = String(valueText.dropFirst())
        } else {
            valueTextField.text = "-" + valueText
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.elements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = elementsTableView.dequeueReusableCell(withIdentifier: "ItemSumCell", for: indexPath) as! ItemSumCell
        
        cell.viewController = self
        cell.delegate = self
        cell.initCell(withItem: item, andElementIndex: indexPath.row, showSeparator: numberSeparator)
        
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
                
                //Utils.debugLog("Successfully removed element of Sum item \(self.item.ID)")
                
                self.itemChangeDelegate?.itemChanged()
                
                self.sumLabel.text = self.item.sum.asString(withSeparator: self.numberSeparator)
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

extension ItemSumViewController {
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        item.exchangeElement(fromIndex: currentIndex.row, toIndex: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        DispatchQueue.global().async {
            var alert: UIAlertController?
            do {
                try self.item.saveToFile()
            } catch let error as Status {
                alert = error.createErrorAlert()
            } catch {
                alert = Status.errorDefault.createErrorAlert()
            }
            
            DispatchQueue.main.async {
                if let alert = alert {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
