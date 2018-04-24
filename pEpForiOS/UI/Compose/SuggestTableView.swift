//
//  SuggestTableView.swift
//
//  Created by Yves Landert on 21.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit
import MessageModel

open class SuggestTableView: UITableView {

    private var identities = [Identity]()


    // MARK: - LIFE CYCLE

    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.dataSource = self
    }

    // MARK: - API

    public func updateContacts(_ string: String) -> Bool {
        hide()
        identities.removeAll()
        
        let search = string.cleanAttachments
        if (search.count >= 3) {
            identities = Identity.by(snippet: search)
            
            if identities.count > 0 {
                reloadData()
                isHidden = false
            }
        } else {
            hide()
            reloadData()
        }
 
        return !isHidden
    }
    
    public func hide() {
        isHidden = true
    }
    
    public func didSelectIdentity(index: IndexPath) -> Identity?  {
        hide()
        return identities[index.row]
    }
}

// MARK: - UITableViewDataSource

extension SuggestTableView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return identities.count
    }

    public func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(
            withIdentifier: "contactCell", for: indexPath) as! ContactCell

        cell.updateCell(identities[indexPath.row])

        return cell
    }
}
