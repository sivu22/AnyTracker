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
    var listTitle: String!
    var allItems: Bool = false
    var alert: UIAlertController?
    
    var list: List?             // The current list (nil for ALL)
    var items: [Item] = []      // All the items that can be seen in the VC
    
    fileprivate var addItem: Item? = nil
    fileprivate var addItemIndex: Int = 0
    fileprivate var itemUpdated: Bool = false
    fileprivate var editItemIndex: Int = -1
    
    fileprivate var refreshItem: Bool = false
    fileprivate var refreshItemIndex: Int = -1
    
    var numItems: Int = -1
    
    fileprivate var reorderTableView: LongPressReorderTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
        
        alert = nil
        if listName == "all" {
            allItems = true
            // ALL is only for looking at available items (readonly)
            addButton.hide()
            
            // Build up the list of items
            if let app = app, let lists = app.lists {
                DispatchQueue.global().async {
                    let listIDs = lists.getListIDs()
                    
                    for list in listIDs {
                        let itemIDs = List.getItemIDs(fromList: list)
                        for itemID in itemIDs {
                            do {
                                let item = try Items.loadItem(withID: itemID)
                                self.items.append(item)
                            } catch let error as Status {
                                self.alert = error.createErrorAlert()
                            } catch {
                                self.alert = Status.ErrorDefault.createErrorAlert()
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.numItems = self.items.count
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            title = listTitle
            
            DispatchQueue.global().async {
                do {
                    self.list = try List.loadListFromFile(self.listName)
                    self.numItems = self.list!.numItems
                    
                    for itemID in self.list!.items {
                        let item = try Items.loadItem(withID: itemID)
                        self.items.append(item)
                    }
                } catch let error as Status {
                    self.alert = error.createErrorAlert()
                } catch {
                    self.alert = Status.ErrorDefault.createErrorAlert()
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                    if let alert = self.alert {
                        self.addButton.isEnabled = false
                        if self.presentedViewController == nil {
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    self.reorderTableView = LongPressReorderTableView(self.tableView)
                    self.reorderTableView.delegate = self
                    self.reorderTableView.enableLongPressReorder()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if addItem != nil && addItemIndex > -1 {
            // Item is already added to list and written on disk
            numItems += 1
            delegate?.numItemsChange(increased: true)
            
            if addItemIndex == 0 {
                items.insert(addItem!, at: 0)
            } else {
                items.append(addItem!)
            }
            
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
        return numItems == items.count ? numItems : items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell

        cell.initCell(withItem: items[(indexPath as NSIndexPath).row], separator: app?.numberSeparator ?? true, longFormat: app?.dateFormatLong ?? true)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID: String = items[(indexPath as NSIndexPath).row].ID
        
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
        let index = (indexPath as NSIndexPath).row
        var alert: UIAlertController?
        
        DispatchQueue.global().async {
            do {
                let _ = Items.deleteItemFile(withID: self.list!.items[index])
                try self.list!.removeItem(atIndex: index)
            }  catch let error as Status {
                alert = error.createErrorAlert()
            } catch {
                alert = Status.ErrorDefault.createErrorAlert()
            }
            
            DispatchQueue.main.async {
                if alert != nil {
                    self.present(alert!, animated: true, completion: nil)
                    return
                }
                
                self.numItems -= 1
                self.delegate?.numItemsChange(increased: false)
                
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let itemIndex = (indexPath as NSIndexPath).row
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            let vcNav = self.storyboard!.instantiateViewController(withIdentifier: "NewItemNavigation") as! UINavigationController
            let vc = vcNav.childViewControllers[0] as! NewItemViewController
            vc.delegateEdit = self
            self.editItemIndex = itemIndex
            self.itemUpdated = false
            vc.longDateFormat = self.app?.dateFormatLong ?? true
            vc.editItem = self.items[itemIndex]
            
            self.present(vcNav, animated: true, completion: nil)
            
            self.tableView.setEditing(false, animated: true)
        }
        edit.backgroundColor = UIColor.lightGray
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            let item = self.items[itemIndex]
            
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
        let itemIndex = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? -1
        let itemIDIndex = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? 0
        
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
            refreshItemIndex = itemIndex
            vc.item = items[itemIDIndex] as! ItemSum
        }
        else if identifier == "toCounterItem" {
            let vc = segue.destination as! ItemCounterViewController
            vc.numberSeparator = app?.numberSeparator ?? true
            vc.itemChangeDelegate = self
            refreshItemIndex = itemIndex
            vc.item = items[itemIDIndex] as! ItemCounter
        }
        else if identifier == "toJournalItem" {
            let vc = segue.destination as! ItemJournalViewController
            vc.itemChangeDelegate = self
            vc.longDateFormat = app?.dateFormatLong ?? true
            refreshItemIndex = itemIndex
            vc.item = items[itemIDIndex] as! ItemJournal
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
}

// MARK: - Long press drag and drop reorder

extension ItemsTableViewController {
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        list!.exchangeItem(fromIndex: currentIndex.row, toIndex: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        // Save the new list of items IDs
        DispatchQueue.global().async {
            var alert: UIAlertController?
            
            do {
                try self.list!.saveListToFile()
            } catch let error as Status {
                alert = error.createErrorAlert()
            } catch {
                alert = Status.ErrorDefault.createErrorAlert()
            }
            
            if alert != nil {
                DispatchQueue.main.async {
                    self.present(alert!, animated: true, completion: nil)
                }
            }
        }
    }
}
