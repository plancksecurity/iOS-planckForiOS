//
//  Log+Pantomime.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

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
