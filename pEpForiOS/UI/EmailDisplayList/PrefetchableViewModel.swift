//
//  PrefetchableViewModel.swift
//  pEp
//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol PrefetchableViewModel {

    func loadData()

    func cancelLoad()
    
}
