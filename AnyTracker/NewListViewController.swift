//
//  NewListViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 17/03/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

protocol NewListDelegate: class {
    func newListName(_ name: String, sender: NewListViewController)
}

class NewListViewController: UIViewController, UITextFieldDelegate {

    weak var delegate: NewListDelegate?
    @IBOutlet weak var listNameTextField: UITextField!
    
    fileprivate var editMode: Bool = false
    var listName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listNameTextField.delegate = self
        
        if listName != "" {
            editMode = true
            listNameTextField.text = listName
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        listNameTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let count = textField.text?.count ?? 0
        if count > 0 {
            if !editMode || textField.text! != listName {
                delegate?.newListName(textField.text!, sender: self)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
        
        return true
    }
    
    func prepareForDismissingController() {
        if listNameTextField.isFirstResponder {
            listNameTextField.resignFirstResponder()
        }
    }
}
