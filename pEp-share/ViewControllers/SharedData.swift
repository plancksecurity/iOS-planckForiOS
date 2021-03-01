//
//  SharedData.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 01.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

/// The different data types supported by this extension
public enum SharedType {
    case Picture (UIImage)
    case Url (URL)
    case PlainText (String)
}

/// Stores items shared by the user, complete with their types and the  data (once loaded).
public class SharedData {
    /// All the data the user wants to share, in association with the `NSExtensionItem`
    /// that was used.
    ///
    /// The association with `NSExtensionItem` is needed to uphold the order (if any),
    /// in which the data was shared, despite of the async loading of it.
    private var foundExtensionsMap = [NSExtensionItem:SharedType]()

    /// The queue to serialize access to `foundExtensionsMap`.
    private let extensionStoreQueue = DispatchQueue(label: "SharedViewControllerStoreQueue",
                                                    qos: .userInitiated)
}
