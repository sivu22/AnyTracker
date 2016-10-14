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
    
    var activeView: UIView?
    
    var itemChangeDelegate: ItemChangeDelegate?
    
    var item: ItemSum!
    var numberSeparator: Bool = false
    var keyboardVisible: Bool = false
    var shownKeyboardHeight: CGFloat = 0
    
    var viewOffset: CGFloat = 0
    var keyboardAnimationDuration: Double = Constants.Animations.keyboardDuration
    var keyboardAnimationCurve: UIViewAnimationCurve = Constants.Animations.keyboardCurve
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = item.name
        
        addButton.disable()
        sumLabel.text = item.sum.asString(withSeparator: numberSeparator)
        
        elementsTableView.delegate = self
        elementsTableView.dataSource = self
        elementsTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        nameTextField.delegate = self
        valueTextField.delegate = self
        Utils.addDoneButton(toTextField: valueTextField, forTarget: view, negativeTarget: self, negativeSelector: #selector(ItemSumViewController.negativePressed))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ItemSumViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ItemSumViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? Constants.Animations.keyboardDuration
        keyboardAnimationCurve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? Constants.Animations.keyboardCurve.rawValue)!
        
        let activeControlRect: CGRect = activeView!.frame
        var lastVisiblePoint: CGPoint = CGPoint(x: activeControlRect.origin.x, y: activeControlRect.origin.y + activeControlRect.height + Constants.Animations.keyboardDistanceToControl)
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
