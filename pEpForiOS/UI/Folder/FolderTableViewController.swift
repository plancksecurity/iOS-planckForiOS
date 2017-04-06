//
//  FolderTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class FolderTableViewController: UITableViewController {

    var sectionsmap = [Bool]()
    var appConfig: AppConfig?

    var folderVM = FolderViewModel()

    var folderToShow :Folder?

    override func viewDidLoad() {
        super.viewDidLoad()
        //initialConfig()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        //tableView.register(CollapsibleTableViewHeader.self, forHeaderFooterViewReuseIdentifier: "header")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderVM.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderVM[section].count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sectionsmap.count > section {
            return nil
        }
        let header :CollapsibleTableViewHeader?
        if let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader{
            header = head
        } else {
            header = CollapsibleTableViewHeader(reuseIdentifier: "header")
        }
        sectionsmap.append(true)
        header!.configure(viewModel: folderVM[section], section: section)
        header!.delegate = self
        return header
        /*let label = UILabel()
        label.textAlignment = .left
        label.text = "I'm a test label"
        label.tag = section

        let tap = UITapGestureRecognizer(target: self, action: #selector(FolderTableViewController.tapFunction))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        sectionsmap.append(true)

        return label*/
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    /*verride func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     return 80.0
     }*/

    /*override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
     return folderVM[section].title
     //reimplement to a custom view and copy the view of mail app
     }*/

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        let fcvm = folderVM[indexPath.section][indexPath.item]
        cell.detailTextLabel?.text = "\(fcvm.number)"
        cell.textLabel?.text = fcvm.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath)
        -> Int {
        return folderVM[indexPath.section][indexPath.item].level
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        folderToShow = folderVM[indexPath.section][indexPath.item].folder
        performSegue(withIdentifier: "ShowFolder", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? EmailListViewController
            , let folder = folderToShow {
            let config = EmailListConfig(appConfig: appConfig, folder: folder)
            controller.config = config
        }
    }

    @IBAction func addAccount(_ sender: Any) {
    }

    func tapFunction(sender:UITapGestureRecognizer) {
        let section = sender.view!.tag
        let oldcount = folderVM[section].count
        folderVM[section].collapse()
        var newcount = folderVM[section].count
        if oldcount > newcount {
            newcount = oldcount
        }
        let indexPaths = (0..<newcount).map { i in return IndexPath(item: i, section: section)  }

        //hidden[section] = !hidden[section]

        tableView?.beginUpdates()
        if folderVM[section].collapsed {
            tableView?.deleteRows(at: indexPaths, with: .automatic)
        } else {
            tableView?.insertRows(at: indexPaths, with: .automatic)
        }
        tableView?.endUpdates()
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

extension FolderTableViewController: CollapsibleTableViewHeaderDelegate {

    func toggleSection(header: CollapsibleTableViewHeader, section: Int) {
        let oldcount = folderVM[section].count
        folderVM[section].collapse()
        var newcount = folderVM[section].count
        if oldcount > newcount {
            newcount = oldcount
        }
        var indexpath = [IndexPath]()
        for i in 0 ..< newcount {
            indexpath.append(NSIndexPath(row: i, section: section) as IndexPath)
        }
        tableView.beginUpdates()
            if folderVM[section].collapsed {
                tableView.deleteRows(at: indexpath, with: UITableViewRowAnimation.automatic)
            } else {
                tableView.insertRows(at: indexpath, with: UITableViewRowAnimation.automatic)
            }
        tableView.endUpdates()
    }
    
}
