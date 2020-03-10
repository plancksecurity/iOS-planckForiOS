//
//  Log+Extension.swift
//  MessageModel
//
//  Created by Xavier Algarra on 04/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpUtilities

extension Log: CWLogging {
    @objc open func infoComponent(_ component: String, message: String) {
        Log.info(component: component, content: message)
    }

    @objc open func warnComponent(_ component: String, message: String) {
        Log.warn(component: component, content: message)
    }

    @objc open func errorComponent(_ component: String, message: String) {
        Log.error(component: component, errorString: message)
    }
}
