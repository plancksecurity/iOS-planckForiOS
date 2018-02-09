//
//  PEPIdentity+ProviderUtils.swift
//  pEp
//
//  Created by Andreas Buff on 29.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - ProviderUtils

///*
// Somehow nasty but required provider specific rules.
// */
//
//extension PEPIdentity {
//
//    //BUFF: obsolete!?
//    //    /// Certain providers append messages on server side for certain folder types.
//    //    /// The only currently known case is Gmail Sent folder.
//    //    ///
//    //    /// - Parameter type: folder type to check
//    //    /// - Returns: whether or not the provider appends messages on server side
//    //    ///             for the given for the given folder type
//    //    func providerDoesHandleAppend(forFolderOfType type: FolderType) -> Bool {
//    //        if type == .sent {
//    //            return address.isGmailAddress
//    //        }
//    //        return false
//    //    }
//
//    /// Whether or not the default destructive action is "archive" instead of "delete".
//    var defaultDestructiveActionIsArchive: Bool {
//        // Currently Gmail is the only known and used provider.
//        return address.isGmailAddress
//    }
//}

