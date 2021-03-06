//
//  ListsTableViewController.swift
//  AnyTracker
//
//  Created by Cristian Sava on 08/02/16.
//  Copyright © 2016 Cristian Sava. All rights reserved.
//

import UIKit

extension UITableViewController {
    func reloadRows(at indexes: [Int], in section: Int = 0, withAnimation animation: UITableView.RowAnimation = .automatic) {
        var indexArray = [] as [IndexPath]
        for index in indexes {
            let indexPath = IndexPath(row: index, section: section)
            indexArray.append(indexPath)
        }
        
        tableView.reloadRows(at: indexArray, with: animation)
    }
}

class ListsTableViewController: UITableViewController, NewListDelegate, ItemsDelegate {
    
    fileprivate(set) var app: App?
    fileprivate var addListName: String = ""
    fileprivate var editListIndex: Int = -1
    
    fileprivate var mayNeedRefresh: Bool = false
    
    fileprivate var selectedListIndex: Int?
    fileprivate var currentListNumItems: Int = -1
    
    var reorderTableView: LongPressReorderTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        guard let app = app else {
            return
        }
        if !app.noContent {
            DispatchQueue.global().async {
                do {
                    app.lists = try Lists.loadListsFromFile()
                } catch let error as Status {
                    DispatchQueue.main.async {
                        let alert = error.createErrorAlert()
                        self.present(alert, animated: true, completion: nil)
                    }
                } catch {
                }
                
                if app.lists == nil {
                    Utils.debugLog("Failed to load lists from file \(Constants.File.lists)")
                } else {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        reorderTableView = LongPressReorderTableView(tableView)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let app = app else {
            return
        }
        
        // No cache = no bueno
        if app.lists != nil && app.lists!.cache == nil {
            let alert = Status.errorListsBadCache.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
        
        // Back from Items
        if let listIndex = selectedListIndex {
            selectedListIndex = nil
            
            if currentListNumItems - app.lists!.getListNumItems(atIndex: listIndex) != 0 {
                app.lists!.changedList(atIndex: listIndex, withNumItems: currentListNumItems)
                
                reloadRows(at: [listIndex + 1, 0])
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
        return 1 + (app?.lists?.listsData.count ?? 0)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListCell
    
        if indexPath.row == 0 {
            cell.initCellWithName(Constants.Text.listAll, andItems: app?.lists?.cache?.numItemsAll ?? 0)
        } else {
            let index = indexPath.row - 1
            cell.initCellWithName(app?.lists?.cache?.lists[index].name ?? "<Name>", andItems: app?.lists?.cache?.lists[index].numItems ?? 0)
        }
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
    fileprivate func deleteList(atIndex index: Int, withIndexPath indexPath: IndexPath) {
        guard let app = app else {
            return
        }
        
        let numItems = app.lists!.deleteList(atIndex: index)
        if numItems > -1 {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Update ALL
            if numItems > 0 {
                reloadRows(at: [0])
            }
            
            // Save the new list of IDs
            do {
                try app.lists!.saveListsToFile()
            } catch let error as Status {
                let alert = error.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            } catch {
                let alert = Status.errorDefault.createErrorAlert()
                present(alert, animated: true, completion: nil)
                return
            }
        } else {
            let alert = Status.errorListDelete.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let listIndex = indexPath.row - 1
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "NewList") as! NewListViewController
            vc.delegate = self
            vc.listName = self.app?.lists!.cache?.lists[listIndex].name ?? ""
            self.editListIndex = indexPath.row - 1
            self.present(vc, animated: true, completion: nil)
            
            self.tableView.setEditing(false, animated: true)
        }
        edit.backgroundColor = UIColor.lightGray
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            guard let app = self.app else {
                return
            }
            
            if app.lists!.cache?.lists[listIndex].numItems ?? 0 > 0 {
                let alert = UIAlertController(title: "", message: "Are you sure you want to delete the list and its items?", preferredStyle: UIAlertController.Style.alert)
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: { (action: UIAlertAction!) in
                    self.deleteList(atIndex: listIndex, withIndexPath: indexPath)
                })
                let noAction = UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: { (action: UIAlertAction!) in
                    self.tableView.setEditing(false, animated: true)
                })
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.deleteList(atIndex: listIndex, withIndexPath: indexPath)
        }
        
        return [delete, edit]
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
        if indexPath.row == 0 {
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
        guard let app = app else {
            return
        }
        
        if identifier == "toSettings" {
            let vc = segue.destination.children[0] as! SettingsTableViewController
            vc.injectApp(app)
            
            if !app.noContent {
                mayNeedRefresh = true
            }
        } else if identifier == "toNewList" {
            let vc = segue.destination as! NewListViewController
            vc.delegate = self
        } else if identifier == "toItems" {
            let vc = segue.destination as! ItemsTableViewController
            vc.injectApp(app)
            if let row = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row {
                if row > 0 {
                    let realRow = row - 1
                    vc.listName = app.lists!.listsData[realRow]
                    vc.listTitle = app.lists!.cache?.lists[realRow].name
                    vc.delegate = self
                    selectedListIndex = realRow
                    currentListNumItems = app.lists!.getListNumItems(atIndex: selectedListIndex!)
                }
                else {
                    vc.listName = "all"
                }
            } else {
                vc.listName = ""
            }
        }
    }
    
    func newListName(_ name: String, sender: NewListViewController) {
        addListName = name
        
        guard let app = app else {
            return
        }
        
        if Utils.validString(addListName) {
            let newListName = addListName
            addListName = ""
            
            if editListIndex == -1 {
                if app.lists == nil {
                    app.lists = Lists()
                }
                
                var index = -1
                do {
                    index = try app.lists!.insertList(withName: newListName, atFront: app.addNewListTop)
                    try app.lists!.saveListsToFile()
                } catch let error as Status {
                    let alert = error.createErrorAlert()
                    present(alert, animated: true, completion: nil)
                    return
                } catch {
                    let alert = Status.errorDefault.createErrorAlert()
                    present(alert, animated: true, completion: nil)
                    return
                }
                
                if index >= 0 {
                    if app.noContent {
                        app.toggleNoContent()
                    }
                    
                    tableView.beginUpdates()
                    tableView.insertRows(at: [IndexPath(row: 1 + index, section: 0)], with: UITableView.RowAnimation.right)
                    tableView.endUpdates()
                } else {
                    let alert = Status.errorFailedToAddList.createErrorAlert()
                    present(alert, animated: true, completion: nil)
                }
            } else {
                let listIndex = editListIndex
                editListIndex = -1
                
                do {
                    try app.lists!.updateList(atIndex: listIndex, withNewName: newListName)
                } catch let error as Status {
                    let alert = error.createErrorAlert()
                    present(alert, animated: true, completion: nil)
                    return
                } catch {
                    let alert = Status.errorDefault.createErrorAlert()
                    present(alert, animated: true, completion: nil)
                    return
                }
                
                 reloadRows(at: [listIndex + 1])
            }
        }
    }
    
    func numItemsChange(increased increase: Bool) {
        if increase {
            currentListNumItems += 1
        } else {
            currentListNumItems -= 1
        }
    }
    
    func injectApp(_ app: App) {
        self.app = app
    }
    
    @IBAction func unwindToLists(_ segue: UIStoryboardSegue) {
        let srcVC = segue.source
        if let vc = srcVC as? NewListViewController {
            vc.prepareForDismissingController()
        } else if let _ = srcVC as? SettingsTableViewController {
            guard let app = app else {
                return
            }
            
            if mayNeedRefresh && app.noContent {
                // Cache will properly be empty
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - Long press drag and drop reorder
    
extension ListsTableViewController {
    
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        guard let app = app else {
            return
        }
        
        app.lists!.exchangeList(fromIndex: currentIndex.row - 1, toIndex: newIndex.row - 1)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) {
        guard let app = app else {
            return
        }
        
        // Save the new list of IDs
        do {
            try app.lists!.saveListsToFile()
        } catch let error as Status {
            let alert = error.createErrorAlert()
            present(alert, animated: true, completion: nil)
        } catch {
            let alert = Status.errorDefault.createErrorAlert()
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func startReorderingRow(atIndex indexPath: IndexPath) -> Bool {
        if indexPath.row > 0 {
            return true
        }
        
        return false
    }
    
    override func allowChangingRow(atIndex indexPath: IndexPath) -> Bool {
        if indexPath.row > 0 {
            return true
        }
        
        return false
    }
}
