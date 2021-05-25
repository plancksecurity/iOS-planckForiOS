//
//  SecureWebViewUrlClickHandlerProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 10.02.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol SecureWebViewUrlClickHandlerProtocol: AnyObject {
    /// Called whenever a mailto:// URL has been clicked by the user.
    /// - Parameter url: The mailto:// URL
    func didClickOn(mailToUrlLink url: URL)
}
