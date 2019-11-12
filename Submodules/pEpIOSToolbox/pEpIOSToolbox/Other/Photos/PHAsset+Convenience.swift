//
//  PHAsset+Convenience.swift
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 12.11.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Photos

// MARK: - PHAsset+Convenience

extension PHAsset {

    public func imageData(version: PHImageRequestOptionsVersion = .current,
                          completion: @escaping (Data?)-> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = version
        manager.requestImageDataAndOrientation(for: self, options: options) {  data, _, _, _ in
            completion(data)
        }
    }
}
