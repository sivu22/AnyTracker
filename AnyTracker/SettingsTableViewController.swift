//
//  SettingsTableViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 08/02/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    fileprivate(set) var app: App?
    @IBOutlet weak var separatorSwitch: UISwitch!
    @IBOutlet weak var formatSwitch: UISwitch!
    @IBOutlet weak var listInsertControl: UISegmentedControl!
    @IBOutlet weak var itemInsertControl: UISegmentedControl!
    @IBOutlet weak var clearContentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let app = app else {
            return
        }
        
        if !app.numberSeparator {
            separatorSwitch.setOn(false, animated: false)
        }
        if !app.dateFormatLong {
            formatSwitch.setOn(false, animated: false)
        }
        if app.addNewListTop {
            listInsertControl.selectedSegmentIndex = 0
        }
        if app.addNewItemTop {
            itemInsertControl.selectedSegmentIndex = 0
        }
        if app.noContent {
            clearContentButton.isEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 3 {
            let headerView = view as! UITableViewHeaderFooterView
            headerView.textLabel?.text = "AnyTracker " + App.version
            headerView.textLabel?.textAlignment = NSTextAlignment.center
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footerView = view as! UITableViewHeaderFooterView
        footerView.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    func injectApp(_ app: App) {
        self.app = app
    }

    // MARK: - Actions
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if let app = app {
            if sender == separatorSwitch {
                app.toggleNumberSeparator()
            } else if sender == formatSwitch {
                app.toggleDateFormatLong()
            }
        }
    }
    
    @IBAction func listInsertChanged(_ sender: AnyObject) {
        if let app = app {
            app.toggleAddNewListTop()
        }
    }
    
    @IBAction func itemInsertChanged(_ sender: AnyObject) {
        if let app = app {
            app.toggleAddNewItemTop()
        }
    }
    
    @IBAction func clearContentPressed(_ sender: UIButton) {
        if let app = app {
            if let lists = app.lists {
                let alert = UIAlertController(title: "Clear Content", message: "All lists and all items will be deleted. Are you sure you want to continue?", preferredStyle: UIAlertControllerStyle.alert)
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction!) in
                    Utils.debugLog("App content reset wanted")
                    
                    var success = true
                    do {
                        try lists.deleteLists()
                    } catch let error as Status {
                        success = false
                        
                        let alertError = error.createErrorAlert()
                        self.present(alertError, animated: true, completion: nil)
                    } catch {
                        success = false
                    }
                    
                    if success && lists.listsData.count == 0 {
                        app.toggleNoContent()
                        
                        self.clearContentButton.isEnabled = false
                    }
                    })
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(yesAction)
                alert.addAction(noAction)
                present(alert, animated: true, completion: nil)
            }
        }
    }
}
