//
//  MessageQueryResultsFilter+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 03/05/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension MessageQueryResultsFilter {

    public func getFilterText() -> String{
        var finalString = ""

        var totalFilter = 0

        let onlyEnabledAccounts = accountsEnabledStates.filter { dict in
            guard let testee = dict.values.first else {
                return false
            }
            return testee
        }

        if onlyEnabledAccounts.count != accountsEnabledStates.count {
            if onlyEnabledAccounts.count == 1 {
                finalString = NSLocalizedString("some address",
                                                comment: "Title for address filter")
            }
            totalFilter += onlyEnabledAccounts.count
        }

        if mustBeUnread ?? false {
            finalString = NSLocalizedString("Unread", comment: "Title for unread filter")
            totalFilter += 1
        }
        if mustBeFlagged ?? false {
            finalString = NSLocalizedString("Flagged", comment: "Title for Flagged filter")
            totalFilter += 1
        }
        if mustContainAttachments ?? false {
            finalString = NSLocalizedString("With attachments",
                                            comment: "Title for attachments filter")
            totalFilter += 1
        }
        if totalFilter > 1 {
            return String(format: NSLocalizedString("%d filters",
                                                    comment: "Number of filters instead of filter name"),
                          totalFilter)
        }
        return finalString
    }
}


/*
 let accountNumber = Account.all().count
 var filters = filtersEnabled.count
 if self.isUnified() {
 if removeAccountTitlesIfNeeded(accountNumber: accountNumber) {
 filters = filters - 1 - accountNumber
 } else {
 filters = filters - 1
 }
 }
 if filters > 1 {
 return "\(filters) " + NSLocalizedString("Filters", comment: "Filter Title")
 } else {
 var titles = [String]()
 self.filtersEnabled.forEach { (filter) in
 if !filter.title.isEmpty {
 titles.append(filter.title)
 }
 }
 return titles.joined(separator: ", ")
 }
 */
