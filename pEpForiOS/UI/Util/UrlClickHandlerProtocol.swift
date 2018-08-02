//
//  UrlClickHandlerProtocol.swift
//  pEp
//
//  Created by Andreas Buff on 02.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol UrlClickHandlerProtocol: class {
    /// Called whenever a mailto:// URL has been clicked by the user.
    /// - Parameters:
    ///   - sender: caller of the message
    ///   - mailToUrlClicked: the clicked URL
    func didClickMailToUrlLink(sender: AnyObject, url: URL)
}
