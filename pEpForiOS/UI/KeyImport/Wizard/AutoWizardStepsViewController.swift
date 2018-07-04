//
//  AutoWizardStepsViewController.swift
//  pEp
//
//  Created by Hussein on 22/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/*
//TODO: ADD ModelView
 Has to go to Model:
 private var keyImportWizzard: KeyImortWizzard
 init(keyImortService: KeyImortServiceProtocol) {
    self.keyImortWizzard = KeyImortWizzard(keyImportService: keyImortService)
    super.init()
 }
 */
class AutoWizardStepsViewController: BaseViewController {
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var stepDescription: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup

    private func setup() {
        guard let appConfig = appConfig else {
            Log.shared.errorAndCrash(component: #function, errorString: "No config")
            return
        }
        //TODO: setup model passing import service
//        model = Model(keyImportService: appConfig.keyImportService)
    }

    // MARK: - Actions

    //TODO: Use just one IBAction, as start and cancel are complementary

    @IBAction func onStartClicked(_ sender: Any) {
        //hideStartButton()
        start.isHidden = true
        //showCancelButton()
        cancel.isHidden = false
        //showCurrentStep()
        stepDescription.isHidden = false
        loading.isHidden = false
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        start.isHidden = false
        cancel.isHidden = true
        stepDescription.isHidden = true
        loading.isHidden = true
        //hideStartButton()
        //showCancelButton()
        //showCurrentStep()
    }
}
