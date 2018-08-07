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
    /**
     Use to indicate a transition from a single message view to a thread view.
     */
    func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                            requestsShowThreadViewFor message: Message)
    
    func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                            requestsShowEmailViewFor message: Message)
}
