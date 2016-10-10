//
//  ItemsTableViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 14/06/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

protocol ItemsDelegate: class {
    func numItemsChange(increased increase: Bool)
}

class ItemsTableViewController: UITableViewController, NewItemDelegate, EditItemDelegate, ItemChangeDelegate {

    weak var delegate: ItemsDelegate?
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    fileprivate(set) var app: App?
    
    var listName: String!
    var allItems: Bool = false
    var alert: UIAlertController?
    var alertPresenting: Bool = false
    
    var list: List?             // Items from a certain list are shown
    var items: [String]?        // All items from all lists are shown
    
    fileprivate var addItem: Item? = nil
    fileprivate var addItemIndex: Int = 0
    fileprivate var itemUpdated: Bool = false
    fileprivate var editItemIndex: Int = -1
    
    fileprivate var refreshItem: Bool = false
    fileprivate var refreshItemIndex: Int = -1
    
    var numItems: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if listName == "all" {
            allItems = true
            // ALL is only for looking at available items (readonly)
            addButton.isEnabled = false
            addButton.tintColor = UIColor.clear
            
            // Build up the list of items
            if let app = app, let lists = app.lists {
                let listIDs = lists.getListIDs()
                items = []
                
                for list in listIDs {
                    let itemIDs = List.getItemIDs(fromList: list)
                    for item in itemIDs {
                        items!.append(item)
                    }
                }
            }
        } else {
            alert = nil
            
            do {
                list = try List.loadListFromFile(listName)
                numItems = list!.numItems
            } catch let error as Status {
                alert = error.createErrorAlert()
            } catch {
            }
            
            title = list?.name ?? "Items"
            
            if let alert = alert {
                addButton.isEnabled = false
                if presentedViewController == nil {
                    present(alert, animated: true, completion: nil)
                }
            }
            
            addLongPressGesture()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if addItem != nil && addItemIndex > -1 {
            // Item is already added to list and written on disk
            numItems += 1
            delegate?.numItemsChange(increased: true)
            
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: addItemIndex, section: 0)], with: UITableViewRowAnimation.right)
            tableView.endUpdates()
            
            // Not needed, should be a bool instead
            addItem = nil
        } else if editItemIndex > -1 {
            let itemIndex = editItemIndex
            editItemIndex = -1
            
            if itemUpdated {
                reloadRows(at: [itemIndex])
            }
        } else if refreshItem {
            refreshItem = false
            
            if refreshItemIndex > -1 {
                reloadRows(at: [refreshItemIndex])
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = items {
            return items.count
        }
        
        return list?.numItems ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell

        let itemID: String = getItemID(fromIndex: (indexPath as NSIndexPath).row)
        do {
            let item = try Items.loadItem(withID: itemID)
            cell.initCell(withItem: item, separator: app?.numberSeparator ?? true, longFormat: app?.dateFormatLong ?? true)
        } catch let error as Status {
            if !alertPresenting {
                alertPresenting = true
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: {
                    self.alertPresenting = false
                })
            }
        } catch {
            if !alertPresenting {
                alertPresenting = true
                let alert = Status.ErrorDefault.createErrorAlert()
                present(alert, animated: true, completion: {
                    self.alertPresenting = false
                })
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID: String = getItemID(fromIndex: (indexPath as NSIndexPath).row)
        
        guard let type = Items.getItemType(fromID: itemID) else {
            Utils.debugLog("Can't get item type of item \(itemID) at index \(indexPath)")
            return
        }
        
        switch type {
        case .Sum:
            performSegue(withIdentifier: "toSumItem", sender: indexPath)
        case .Counter:
            performSegue(withIdentifier: "toCounterItem", sender: indexPath)
        case .Journal:
            performSegue(withIdentifier: "toJournalItem", sender: indexPath)
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if allItems {
            return false
        }
        return true
    }

    fileprivate func deleteItem(withIndexPath indexPath: IndexPath) {
        do {
            let _ = Items.deleteItemFile(withID: list!.items[(indexPath as NSIndexPath).row])
            try list!.removeItem(atIndex: (indexPath as NSIndexPath).row)
        }  catch let error as Status {
            let alert = error.createErrorAlert()
            present(alert, animated: true, completion: nil)
            return
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            present(alert, animated: true, completion: nil)
            return
        }
        
        numItems -= 1
        delegate?.numItemsChange(increased: false)
        
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            let vcNav = self.storyboard!.instantiateViewController(withIdentifier: "NewItemNavigation") as! UINavigationController
            let vc = vcNav.childViewControllers[0] as! NewItemViewController
            vc.delegateEdit = self
            self.editItemIndex = (indexPath as NSIndexPath).row
            self.itemUpdated = false
            vc.longDateFormat = self.app?.dateFormatLong ?? true
            
            do {
                let item = try Items.loadItem(withID: self.list?.items[(indexPath as NSIndexPath).row] ?? "")
                vc.editItem = item
            } catch let error as Status {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.present(vcNav, animated: true, completion: nil)
            
            self.tableView.setEditing(false, animated: true)
        }
        edit.backgroundColor = UIColor.lightGray
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            var item: Item!
            do {
                item = try Items.loadItem(withID: self.list?.items[(indexPath as NSIndexPath).row] ?? "")
            } catch let error as Status {
                let alert = error.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if !item.isEmpty() {
                let alert = UIAlertController(title: "", message: "Are you sure you want to delete the item?", preferredStyle: UIAlertControllerStyle.alert)
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction!) in
                    self.deleteItem(withIndexPath: indexPath)
                })
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction!) in
                    self.tableView.setEditing(false, animated: true)
                })
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.deleteItem(withIndexPath: indexPath)
        }
        
        return [delete, edit]
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {

    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if allItems {
            return false
        }
        return true
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toNewItem" {
            let vc = segue.destination.childViewControllers[0] as! NewItemViewController
            vc.list = list!
            vc.longDateFormat = app?.dateFormatLong ?? true
            vc.insertItemAtFront = app?.addNewItemTop ?? false
            vc.delegateNew = self
        } else if identifier == "toSumItem" {
            let vc = segue.destination as! ItemSumViewController
            vc.numberSeparator = app?.numberSeparator ?? true
            vc.itemChangeDelegate = self
            refreshItemIndex = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? -1
            do {
                let item = try Items.loadItem(withID: getItemID(fromIndex: (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? 0)) as! ItemSum
                vc.item = item
            } catch let error as Status {
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
            }
        }
        else if identifier == "toCounterItem" {
            let vc = segue.destination as! ItemCounterViewController
            vc.numberSeparator = app?.numberSeparator ?? true
            vc.itemChangeDelegate = self
            refreshItemIndex = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? -1
            do {
                let item = try Items.loadItem(withID: getItemID(fromIndex: (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? 0)) as! ItemCounter
                vc.item = item
            } catch let error as Status {
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
            }
        }
        else if identifier == "toJournalItem" {
            let vc = segue.destination as! ItemJournalViewController
            vc.itemChangeDelegate = self
            vc.longDateFormat = app?.dateFormatLong ?? true
            refreshItemIndex = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? -1
            do {
                let item = try Items.loadItem(withID: getItemID(fromIndex: (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? 0)) as! ItemJournal
                vc.item = item
            } catch let error as Status {
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
            } catch {
                let alert = Status.ErrorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func unwindToItems(_ segue: UIStoryboardSegue) {
        let srcVC = segue.source as? NewItemViewController
        if let vc = srcVC {
            vc.prepareForDismissingController()
        }
    }
    
    func injectApp(_ app: App) {
        self.app = app
    }
    
    func newItem(_ item : Item, atIndex index: Int, sender: NewItemViewController) {
        addItem = item
        addItemIndex = index
    }
    
    func updateItem(fromSender sender: NewItemViewController) {
        itemUpdated = true
    }
    
    func itemChanged() {
        refreshItem = true
    }
    
    func getItemID(fromIndex index: Int) -> String {
        var itemID: String = ""
        if let list = list {
            itemID = list.items[index]
        } else if let items = items {
            itemID = items[index]
        }
        
        return itemID
    }
    
    // MARK: - Long press drag and drop
    
    override func changedAction() {
        list!.exchangeItem(fromIndex: DragInfo.sourceIndexPath.row, toIndex: DragInfo.destinationIndexPath.row)
    }
    
    override func defaultAction() {
        // Save the new list of items IDs
        do {
            try list!.saveListToFile()
        } catch let error as Status {
            let alert = error.createErrorAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.ErrorDefault.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
    }
}
