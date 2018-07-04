//
//  NeedsRefreshDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 21/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol NeedsRefreshDelegate {
    var requestsReload: (() -> Void)?  {get set}
}
