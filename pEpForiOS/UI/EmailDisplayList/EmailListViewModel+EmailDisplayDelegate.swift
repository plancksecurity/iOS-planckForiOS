//
//  EmailListViewModel+EmailDisplayDelegate.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel
//!!!: this delegates must be fixed
/*
 As far as I can see EmailDisplayDelegate is for communication master <-> detail view.
THis communication is currently disabled. We need to come up with a final concept first and then rewrite it.
 */
extension EmailListViewModel: EmailDisplayDelegate {
    func emailDisplayDidFlag(message: Message) {
        /*guard let index = indexPathShown?.row else {
            //something has gone wrong
            reloadData()
            return
        }
        informUpdateRow(at: index)*/
    }

    func emailDisplayDidUnflag(message: Message) {
        /*guard let index = indexPathShown?.row else {
            //something has gone wrong
            reloadData()
            return
        }
        informUpdateRow(at: index)*/
    }

    func emailDisplayDidDelete(message: Message) {

        /*guard let index = indexPathShown?.row else {
            //something has gone wrong
            reloadData()
            return
        }
        informDeleteRow(at: index)*/

    }

    func emailDisplayDidChangeMarkSeen(message: Message) {
        //updateRow(for: message, isSeenStateChange: true)
    }

    func emailDisplayDidChangeRating(message: Message) {
        //updateRow(for: message)
    }

    private func deleteRow(for message: Message) {
//        DispatchQueue.main.async { [weak self] in
//            guard let index = self?.index(of: message) else {
//                return
//            }
//            self?.informDeleteRow(at: index)
//        }
    }


    private func updateRow(for message: Message, isSeenStateChange: Bool = false) {
//        DispatchQueue.main.async { [weak self] in
//            guard let index = self?.index(of: message) else {
//                return
//            }
//            if isSeenStateChange {
//                self?.informSeenStateChangeForRow(at: index)
//            } else {
//                self?.informUpdateRow(at: index)
//            }
//        }
    }

    ///!!!: change this to work with the proccees like messageQueryResults
//    private func informUpdateRow(at index: Int) {
//        let indexPath = self.indexPath(for: index)
//        //!!!: example of how messageQueryResults communicates with the EmailListVM
//        emailListViewModelDelegate?.willReceiveUpdates(viewModel: self)
//        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
//                                                       didUpdateDataAt: [indexPath])
//        emailListViewModelDelegate?.allUpdatesReceived(viewModel: self)
//    }

    private func informSeenStateChangeForRow(at index: Int) {
        let indexPath = self.indexPath(for: index)
        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didChangeSeenStateForDataAt: [indexPath])
    }

    private func informDeleteRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)

        emailListViewModelDelegate?.emailListViewModel(viewModel: self,
                                                       didRemoveDataAt: [indexPath])
    }

    private func indexPath(for index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
