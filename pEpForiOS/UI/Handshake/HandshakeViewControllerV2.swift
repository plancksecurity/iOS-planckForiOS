//
//  HandshakeViewControllerV2.swift
//  pEp
//
//  Created by Martin Brude on 05/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class HandshakeViewControllerV2: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}


extension HandshakeViewControllerV2 : UITableViewDelegate  {
    
}

extension HandshakeViewControllerV2 : UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "handshakePartnerCell",
                                                    for: indexPath) as? HandshakePartnerTableViewCell {
            return cell
        }

        return UITableViewCell()
    }
}
