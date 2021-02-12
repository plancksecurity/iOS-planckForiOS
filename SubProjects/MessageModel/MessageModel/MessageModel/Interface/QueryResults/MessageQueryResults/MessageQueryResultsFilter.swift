//
//  MessageQueryResultsFilter.swift
//  MessageModel
//
//  Created by Xavier Algarra on 25/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox


///Struct that provides a interface to select which filters are enabled and how must be used.
public struct MessageQueryResultsFilter {
    public let mustBeFlagged: Bool?
    public let mustBeUnread: Bool?
    public let mustContainAttachments: Bool?
    //!!!: docs please. (do not forget to mention this MUST NOT be empty)
//    public let accounts: [Account]
    /// Accounts, including their enabled state. Filter will only show messages in enabled accounts
    public let accountsEnabledStates: [[Account:Bool]]
    public var accounts: [Account] {
        return accountsEnabledStates.compactMap { $0.first?.key }
    }

    ///All the values of the filter will be used to calculate the predicate
    ///The compoundPredicate will be an or with the subpredicates and will be returnd as a predicate
    public var predicate: NSPredicate {
        get {
            var finalPredicate = [NSPredicate]()
            var attributedPredicates = [NSPredicate]()
            var accountsPredicates = [NSPredicate]()

            if let flagged = mustBeFlagged {
                attributedPredicates.append(CdMessage.PredicateFactory.flagged(value: flagged))
            }
            if let unread = mustBeUnread {
                attributedPredicates.append(CdMessage.PredicateFactory.unread(value: unread))
            }
            if mustContainAttachments ?? false {
                attributedPredicates.append(CdMessage.PredicateFactory.hasViewableAttachments())
            }
            if !attributedPredicates.isEmpty {
                finalPredicate.append(NSCompoundPredicate(orPredicateWithSubpredicates: attributedPredicates))
            }

            guard !accountsEnabledStates.isEmpty else {
                Log.shared.errorAndCrash("empty predicate.")
                return NSCompoundPredicate(andPredicateWithSubpredicates: finalPredicate)
            }

            for accountEnabledState in accountsEnabledStates {
                guard
                    let currentDict = accountEnabledState.first,
                    currentDict.value == true
                else {
                    // Disabled accounts are ignored
                    continue
                }
                let account = currentDict.key
                let address = account.user.address
                let accPredicate = CdMessage.PredicateFactory.belongingToAccountWithAddress(
                    address: address)
                accountsPredicates.append(accPredicate)
            }
            finalPredicate.append(NSCompoundPredicate(orPredicateWithSubpredicates: accountsPredicates))
            return NSCompoundPredicate(andPredicateWithSubpredicates: finalPredicate)
        }
    }

    ///Creates a MessageQueryResultsFilter
    ///that can be used to get the predicates for the different filters setted.
    ///
    /// - Parameters:
    ///   - mustBeFlagged: handle the flagged value:
    ///                    true = show flagged
    ///                    false = not show flagged
    ///                    nil = flagged state ignored
    ///   - mustBeUnread: handle the read status:
    ///                   true = show unread
    ///                   false = not show unread
    ///                   nil = unread status ignored
    ///   - mustContainAttachments: used to know if the message contains attachments:
    ///                             true = show only messages with attachemnts
    ///                             false = show only messages without attachments
    ///                             nil = attachments are ignored
    ///   - accounts:   Accounts, including their enabled state. Filter will only show messages
    ///                 in enabled accounts. MUST NOT be empty.
    public init(mustBeFlagged: Bool? = nil,
                mustBeUnread: Bool? = nil,
                mustContainAttachments: Bool? = nil,
                accountEnabledStates: [[Account:Bool]]) {
        self.mustBeFlagged = mustBeFlagged
        self.mustBeUnread = mustBeUnread
        self.mustContainAttachments = mustContainAttachments
        self.accountsEnabledStates = accountEnabledStates
    }

    ///Creates a MessageQueryResultsFilter
    ///that can be used to get the predicates for the different filters setted.
    ///
    /// - Parameters:
    ///   - mustBeFlagged: handle the flagged value:
    ///                    true = show flagged
    ///                    false = not show flagged
    ///                    nil = flagged state ignored
    ///   - mustBeUnread: handle the read status:
    ///                   true = show unread
    ///                   false = not show unread
    ///                   nil = unread status ignored
    ///   - mustContainAttachments: used to know if the message contains attachments:
    ///                             true = show only messages with attachemnts
    ///                             false = show only messages without attachments
    ///                             nil = attachments are ignored
    ///   - accounts:   Accounts to take into account. All given accounts are set to enabled.
    public init(mustBeFlagged: Bool? = nil,
                mustBeUnread: Bool? = nil,
                mustContainAttachments: Bool? = nil,
                accounts: [Account]) {
        self.mustBeFlagged = mustBeFlagged
        self.mustBeUnread = mustBeUnread
        self.mustContainAttachments = mustContainAttachments
        var enabledStates = [[Account:Bool]]()
        for account in accounts {
            enabledStates.append([account:true])
        }
        self.accountsEnabledStates = enabledStates
    }

    public func account(at row: Int) -> Account? {
        guard let accountState = accountsEnabledStates[row].first else {
            Log.shared.errorAndCrash("No states")
            return nil
        }
        return accountState.key
    }
}

// Mark: - Hashable

extension MessageQueryResultsFilter: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(predicate.description)
    }
}

// Mark: - Equatable

extension MessageQueryResultsFilter : Equatable {
    public static func ==(lhs: MessageQueryResultsFilter, rhs: MessageQueryResultsFilter) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Convenience

extension MessageQueryResultsFilter {

    public var numEnabledAccounts: Int {
        let enabledAccounts = accountsEnabledStates.compactMap {
            ($0.first?.value == true ? $0.first?.key: nil) ?? nil
        }
        return enabledAccounts.count
    }
}
