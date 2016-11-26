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
        do {
            try item.changeCounter(byIncreasing: true)
            itemChangeDelegate?.itemChanged()
            UIView.transition(with: counterLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    self.counterLabel.text = self.item.counter.asString(withSeparator: self.numberSeparator)
                }, completion: nil)
        }  catch let error as Status {
            let alert = error.createErrorAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.errorDefault.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
        
        if !decButton.isEnabled {
            decButton.isEnabled = true
        }
    }
    
    @IBAction func decPressed(_ sender: UIButton) {
        do {
            try item.changeCounter(byIncreasing: false)
            itemChangeDelegate?.itemChanged()
            UIView.transition(with: counterLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    self.counterLabel.text = self.item.counter.asString(withSeparator: self.numberSeparator)
                }, completion: nil)
        }  catch let error as Status {
            let alert = error.createErrorAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.errorDefault.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
        
        if item.counter == 0 {
            decButton.isEnabled = false
        }
    }
}
