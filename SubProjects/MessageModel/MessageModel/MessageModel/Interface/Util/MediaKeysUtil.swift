//
//  MediaKeysUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 12/9/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS
import PEPObjCTypes_iOS
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// https://dev.pep.foundation/Engine/Media%20keys
public class MediaKeysUtil {

    /// Expose the init outside MM.
    public init() {}

    /// Configure media keys.
    /// The media keys must follow the format: [pattern:fingerpint]
    public func configure(patternsWithFingerprints: [[String]]) {
        let tuples = MediaKeysUtil.toTuples(arrayOfArrayOfString: patternsWithFingerprints)
        let pairs = tuples.map { PEPMediaKeyPair(pattern: $0, fingerprint: $1) }
        PEPObjCAdapter.configureMediaKeys(pairs)
    }

    /// Transforms an `Array` of `Array` of something to an `Array` of tuples, ignoring any element
    /// that doesn't have exactly two elements.
    static public func toTuples(arrayOfArrayOfString: [[String]]) -> [(String, String)] {
        return arrayOfArrayOfString.compactMap { array in
            if array.count != 2 {
                return nil
            }
            return (array[0], array[1])
        }
    }
}

