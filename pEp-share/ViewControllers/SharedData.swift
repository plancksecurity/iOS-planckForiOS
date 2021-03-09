//
//  SharedData.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 01.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import PEPIOSToolboxForAppExtensions

/// The different data types that can be shared, together with their payload
public enum SharedType {
    /// Some general-purpose text (shared as-is),
    /// together with an optional title
    case plainText (NSAttributedString?, String)

    /// A simple URL (shared as-is, nothing gets loaded),
    /// together with an optional title
    case url (NSAttributedString?, URL)

    /// Image with optional titile, loaded image, the corresponding
    /// data, and the mime type,
    /// together with an optional title
    ///
    /// Will get inlined in the message.
    case image (NSAttributedString?, UIImage, Data, String)

    /// A general file, not getting inlined,
    /// together with an optional title
    case file (NSAttributedString?, Data)
}

/// Stores items shared by the user, complete with their types and the  data (once loaded).
public class SharedData {
    /// Add a loaded item to share.
    public func add(itemProvider: NSItemProvider, dataWithType: SharedType) {
        manipulationQueue.sync { [weak self] in
            guard let me = self else {
                // assume the user canceled the sharing
                return
            }
            me.itemProviders.append(itemProvider)
            me.loadedDataMap[itemProvider] = dataWithType
        }
    }

    /// - Returns: All the downloaded documents ready for sharing.
    public func allSharedTypes() -> [SharedType] {
        var result = [SharedType]()
        for itemProvider in itemProviders {
            guard let sharedData = loadedDataMap[itemProvider] else {
                Log.shared.errorAndCrash("Expected SharedData for NSItemProvider")
                continue
            }
            result.append(sharedData)
        }
        return result
    }

    /// All the data the user wants to share, in association with the `NSExtensionItem`
    /// that was used.
    ///
    /// The association with `NSExtensionItem` is needed to uphold the order (if any),
    /// in which the data was shared, despite of the async loading of it.
    private var loadedDataMap = [NSItemProvider:SharedType]()

    private var itemProviders = [NSItemProvider]()

    /// The queue to serialize access to `foundExtensionsMap`.
    private let manipulationQueue = DispatchQueue(label: "SharedViewControllerStoreQueue",
                                                  qos: .userInitiated)
}
