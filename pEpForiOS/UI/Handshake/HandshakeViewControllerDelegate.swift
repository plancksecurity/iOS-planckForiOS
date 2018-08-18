//
//  HandshakeViewControllerDelegate.swift
//  pEp
//
//  Created by Xavier Algarra on 18/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol HandshakeViewControllerDelegate {

    func handshakeViewController(sender: HandshakeViewController,
                                 didFinishWithResult result: HandshakeViewController.Result)

}
