//
//  ExtraKeysSettingViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

//extension ExtraKeysSettingViewModel {
//
////    struct Row {
////        let fpr: String
////    }
//
//
//}

class ExtraKeysSettingViewModel {
    typealias Fingerprint = String
//    private var rows = [Row]()
    private let fprsOfExtraKeys: [String]

    var numRows: Int {
        return fprsOfExtraKeys.count
    }

    subscript(index: Int) -> Fingerprint {
        get {
            return self.fprsOfExtraKeys[index]
        }
    }

    init() {
        fprsOfExtraKeys = ExtraKeysService.extraKeys.map { $0.fingerprint }
    }



}
//
//// MARK: - Private
//
//extension ExtraKeysSettingViewModel {
//
//    private func setup() {
//        let extraKeys = ExtraKeysService.extraKeys
//    }
//}
