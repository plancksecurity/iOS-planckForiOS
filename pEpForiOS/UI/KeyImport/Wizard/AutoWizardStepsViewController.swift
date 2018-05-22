//
//  AutoWizardStepsViewController.swift
//  pEp
//
//  Created by Hussein on 22/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class AutoWizardStepsViewController: BaseViewController {
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var stepDescription: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
