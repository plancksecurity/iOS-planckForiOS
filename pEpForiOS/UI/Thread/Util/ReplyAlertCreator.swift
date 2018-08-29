//
//  ReplyAlertCreator.swift
//  pEp
//
//  Created by Borja González de Pablo on 27/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class ReplyAlertCreator {

    public let alert: UIAlertController

    public init(){
        alert = UIAlertController.pEpAlertController()
    }

    public func withReplyOption(
        handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        let alertActionReply = UIAlertAction(
            title: NSLocalizedString("Reply", comment: "Message actions"),
            style: .default, handler: handler)
        alert.addAction(alertActionReply)
        return self
    }

    public func withReplyAllOption(
        handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        let alertActionReplyAll = UIAlertAction(
            title: NSLocalizedString("Reply All", comment: "Message actions"),
            style: .default, handler: handler)
        alert.addAction(alertActionReplyAll)
        return self
    }

    public func withFordwardOption(
        handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        let alertActionForward = UIAlertAction(
            title: NSLocalizedString("Forward", comment: "Message actions"),
            style: .default, handler: handler)
        alert.addAction(alertActionForward)
        return self
    }

    public func withCancelOption() -> ReplyAlertCreator {
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Message actions"),
            style: .cancel) { (action) in }
        alert.addAction(cancelAction)
        return self
    }

    public func build()-> UIAlertController{
        return alert
    }
}
