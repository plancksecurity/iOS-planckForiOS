//
//  TutorialViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol TutorialWizardViewModelDelegate: class {
    func dismiss()
}

struct TutorialWizardViewMode {
    
    enum TutorialAction {
        case skip
    }
    
    weak var delegate: TutorialWizardViewModelDelegate?
    
    func handle(action: TutorialAction) {
        switch action {
        case .skip:
            delegate?.dismiss()
        }
    }
}
