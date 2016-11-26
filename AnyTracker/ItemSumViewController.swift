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
    var keyboardAnimationCurve: UIViewAnimationCurve = Constants.Animations.keyboardCurve
    
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
        do {
            try item.insert(element: element)
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
    
        sumLabel.text = item.sum.asString(withSeparator: numberSeparator)
        elementsTableView.beginUpdates()
        elementsTableView.insertRows(at: [IndexPath(row: item.elements.count - 1, section: 0)], with: UITableViewRowAnimation.right)
        elementsTableView.endUpdates()
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
    
    func negativePressed() {
        let valueText = valueTextField.text!
        if valueText.characters.first == "-" {
            valueTextField.text = String(valueText.characters.dropFirst())
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
        cell.initCell(withItem: item, andElementIndex: (indexPath as NSIndexPath).row, showSeparator: numberSeparator)
        
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
            
            sumLabel.text = item.sum.asString(withSeparator: numberSeparator)
            tableView.deleteRows(at: [indexPath], with: .fade)
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
            do {
                try self.item.saveToFile()
            } catch let error as Status {
                DispatchQueue.main.async {
                    let alert = error.createErrorAlert()
                    self.present(alert, animated: true, completion: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = Status.ErrorDefault.createErrorAlert()
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
