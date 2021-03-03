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

/// Shadows `SharedType`, but without any payload, just the casas.
public enum SharedMediaType {
    case image
    case url
    case plainText
    case file
}

/// The different data types that can be shared, together with their payload
public enum SharedType {
    /// Image with optional titile, loaded image, the corresponding data, and the mime type.
    ///
    /// Will get inlined in the message.
    case image (NSAttributedString?, UIImage, Data, String)

    /// A simple URL
    case url (NSAttributedString?, URL)

    /// Some general-purpose text
    case plainText (NSAttributedString?, String)

    /// A general file, probably not getting inlined
    case file (NSAttributedString?, Data)

    public func mediaType() -> SharedMediaType {
        switch self {
        case .image: return .image
        case .url: return .url
        case .plainText: return .plainText
        case .file: return .file
        }
    }
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
