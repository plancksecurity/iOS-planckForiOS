// Message threadding is currently umsupported. The code might be helpful.

////
////  ThreadViewController+TableView.swift
////  pEp
////
////  Created by Miguel Berrocal Gómez on 05/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import SwipeCellKit
//import UIKit
//
//extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {
//
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return model?.rowCount() ?? 0
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if model?.messageisExpanded(at: indexPath.section) == true {
//            return UITableView.automaticDimension
//        }
//        else {
//            return 100
//        }
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if model?.messageisExpanded(at: indexPath.section) == true {
//            return configureCell(identifier: "expandedCell", at: indexPath)
//        }
//        else {
//            return configureCell(identifier: "unexpandedCell", at: indexPath)
//        }
//    }
//
//    func configureCell(identifier:String, at indexPath:IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
//                as? UITableViewCell & MessageViewModelConfigurable,
//            let viewModel = model?.viewModel(for: indexPath.section)  else {
//                return UITableViewCell()
//        }
//        if var refreshableCell = cell as? NeedsRefreshDelegate {
//            refreshableCell.requestsReload = { self.tableView.updateSize() }
//        }
//
//        if let fullCell = cell as? FullMessageCell {
//            fullCell.clickHandler = clickHandler
//        }
//
//        cell.configure(for: viewModel)
//        configureSwipeCell(cell: cell)
//        return cell
//    }
//
//    func configureSwipeCell(cell: UITableViewCell) {
//        guard let cell = cell as? SwipeTableViewCell else {
//            return
//        }
//
//        cell.delegate = self
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if model?.messageisExpanded(at: indexPath.section) == false {
//            model?.messageDidExpand(at: indexPath.section)
//            let indexSet = IndexSet(integer: indexPath.section)
//            tableView.reloadSections(indexSet, with: .automatic)
//        }
//        else {
//            showEmail()
//        }
//    }
//
//    private func showEmail() {
////        guard let splitViewController = self.splitViewController else {
////            logger.errorAndCrash(component: #function,
////                                     errorString: "We must have a splitViewController here")
////            return
////        }
////        if splitViewController.isCollapsed {
//            performSegue(withIdentifier: .segueShowEmail, sender: self)
////        } else {
////            performSegue(withIdentifier: .SegueShowEmailExpanding, sender: self)
////        }
//    }
//}
