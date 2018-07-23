//
//  ScreenComposerProtocol.swift
//  pEp
//
//  Created by Borja González de Pablo on 20/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol ScreenComposerProtocol {
    func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                            requestsShowThreadViewFor message: Message)
    func showSingleView(for indexPath: IndexPath)
}
