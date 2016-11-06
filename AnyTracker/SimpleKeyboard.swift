//
//  SimpleKeyboard.swift
//  AnyTracker
//
//  Created by Cristian Sava on 27/10/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

extension UIView {
    
    func isTextField() -> Bool {
        return self is UITextField
    }
}

// MARK: - SimpleKeyboard implementation

class SimpleKeyboard: NSObject {

    private var targetControls: [UIView]
    fileprivate var viewController: UIViewController
    
    fileprivate var activeView: UIView?
    
    fileprivate var viewOffset: CGFloat = 0
    fileprivate var keyboardAnimationDuration: Double = Constants.Animations.keyboardDuration
    fileprivate var keyboardAnimationCurve: UIViewAnimationCurve = Constants.Animations.keyboardCurve
    
    // MARK: - UITextField callbacks
    
    var textFieldDidBeginEditing: ((_ textField: UITextField)->())?
    var textFieldDidEndEditing: ((_ textField: UITextField)->())?
    var textFieldShouldReturn: ((_ textField: UITextField)->(Bool))?
    
    // MARK: - UITextView callbacks
    
    var textViewShouldBeginEditing: ((_ textView: UITextView)->(Bool))?
    var textViewShouldEndEditing: ((_ textView: UITextView)->(Bool))?
    
    // MARK: - Creation
    
    init(fromViewController vc: UIViewController) {
        targetControls = []
        viewController = vc
    }
    
    private init(withControls controls: [UIView], fromViewController vc: UIViewController) {
        targetControls = controls
        viewController = vc
        super.init()
        
        for control in targetControls {
            setDelegate(forControl: control)
        }
    }
    
    static func createKeyboard(forControls controls: [UIView?], fromViewController vc: UIViewController, andEnable enable: Bool = false) -> SimpleKeyboard? {
        var newKeyboard: SimpleKeyboard?
        var validControls: [UIView] = []
        for control in controls {
            if control != nil {
                if control is UITextField || control is UITextView {
                    validControls.append(control!)
                }
            }
        }
        
        if validControls.count > 0 {
            newKeyboard = SimpleKeyboard(withControls: validControls, fromViewController: vc)
            
            if enable {
                newKeyboard!.enable()
            }
        }
        
        return newKeyboard
    }
    
    // MARK: - Exposed actions
    
    func add(control: UIView, withDoneButtonKeyboard doneButton: Bool = false, doneTarget target: Any? = nil, doneSelector selector: Selector? = nil) {
        if control is UITextField || control is UITextView {
            targetControls.append(control)
            setDelegate(forControl: targetControls[targetControls.count - 1])
            
            if doneButton {
                SimpleKeyboard.addKeyboardDoneButton(forInput: control, fromViewController: viewController, withTarget: target, doneSelector: selector)
            }
        }
    }
    
    func enable() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func disable() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Manually override the active input control
    func setActive(view: UIView) {
        activeView = view
    }
    
    // Manually clear the active input control
    func clearActiveView() {
        activeView = nil
    }
    
    // MARK: - Helpers
    
    private func setDelegate(forControl control: UIView) {
        if control.isTextField() {
            (control as! UITextField).delegate = self
        } else {
            (control as! UITextView).delegate = self
        }
    }
}

// MARK: - Toolbar with done button

extension SimpleKeyboard {
    
    static fileprivate func createToolbarWithDoneButton(_ vc: UIViewController, _ target: Any? = nil, _ selector: Selector? = nil) -> UIToolbar
    {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.backgroundColor = UIColor.white
        keyboardToolbar.sizeToFit()
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: target == nil ? vc.view : target, action: selector == nil ? #selector(UIView.endEditing(_:)) : selector)
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        
        return keyboardToolbar
    }
    
    static func addKeyboardDoneButton(forInput input: UIView, fromViewController vc: UIViewController, withTarget target: Any? = nil, doneSelector selector: Selector? = nil)
    {
        let toolbar = createToolbarWithDoneButton(vc, target, selector)
        
        if input is UITextField {
            (input as! UITextField).inputAccessoryView = toolbar
        } else if input is UITextView {
            (input as! UITextView).inputAccessoryView = toolbar
        }
    }
}

// MARK: - Keyboard notifications

extension SimpleKeyboard {
    
    func keyboardWillShow(_ notification: NSNotification) {
        var keyboardHeight: CGFloat = 0
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
        
        var viewHeight = viewController.view.frame.size.height
        if viewOffset == 0 {
            viewHeight -= keyboardHeight
        } else {
            return
        }
        
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? Constants.Animations.keyboardDuration
        keyboardAnimationCurve = UIViewAnimationCurve(rawValue: (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? Constants.Animations.keyboardCurve.rawValue)!
        
        guard activeView != nil else {
            return
        }
        let activeViewRect: CGRect = activeView!.frame
        var lastVisiblePoint: CGPoint = CGPoint(x: activeViewRect.origin.x, y: activeViewRect.origin.y + activeViewRect.height + Constants.Animations.keyboardDistanceToControl)
        lastVisiblePoint = activeView!.superview?.convert(lastVisiblePoint, to: nil) ?? lastVisiblePoint
        
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
    
    // MARK: - View operations
    
    fileprivate func adaptView(moveUp: Bool)
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
        viewController.view.frame = viewController.view.frame.offsetBy(dx: 0, dy: movementDistance)
        UIView.commitAnimations()
    }
    
    fileprivate func getParentYCoord(forView view: UIView) -> CGFloat {
        guard let superView = view.superview else {
            return 0
        }
        
        if superView == viewController.view {
            return 0
        }
        
        return superView.frame.origin.y + getParentYCoord(forView: superView)
    }
}

// MARK: - Delegates

extension SimpleKeyboard: UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - UITextField
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeView = textField
        textFieldDidBeginEditing?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeView = nil
        textFieldDidEndEditing?(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textFieldShouldReturn?(textField) ?? true
    }
    
    // MARK: - UITextView
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        activeView = textView
        return textViewShouldBeginEditing?(textView) ?? true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        activeView = nil
        
        return textViewShouldEndEditing?(textView) ?? true
    }
}
