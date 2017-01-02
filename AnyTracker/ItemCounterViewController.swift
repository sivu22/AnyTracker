//
//  ItemCounterViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 20/08/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class ItemCounterViewController: UIViewController, NotifyItemUpdate {
    
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var incButton: UIButton!
    @IBOutlet weak var decButton: UIButton!
    
    var itemChangeDelegate: ItemChangeDelegate?
    
    var item: ItemCounter!
    var numberSeparator: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = item.name
        
        counterLabel.text = item.counter.asString(withSeparator: numberSeparator)
        if item.counter == 0 {
            decButton.isEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func incPressed(_ sender: UIButton) {
        item.changeCounter(byIncreasing: true) { error in
            if let error = error {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            self.itemChangeDelegate?.itemChanged()
            UIView.transition(with: self.counterLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.counterLabel.text = self.item.counter.asString(withSeparator: self.numberSeparator)
            }, completion: nil)
            
            if !self.decButton.isEnabled {
                self.decButton.isEnabled = true
            }
        }
    }
    
    @IBAction func decPressed(_ sender: UIButton) {
        item.changeCounter(byIncreasing: false) { error in
            if let error = error {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            self.itemChangeDelegate?.itemChanged()
            UIView.transition(with: self.counterLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.counterLabel.text = self.item.counter.asString(withSeparator: self.numberSeparator)
            }, completion: nil)
            
            if self.item.counter == 0 {
                self.decButton.isEnabled = false
            }
        }
    }
}
