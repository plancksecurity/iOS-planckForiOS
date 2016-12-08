//
//  TableDataModel.swift
//  MailComposer
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit

class ComposeDataSource: NSObject {
    
    var rows = [ComposeFieldModel]()
    var ccEnabled = false
    
    init(with dataArray: [[String: Any]]) {
        for item in dataArray {
            let row = ComposeFieldModel(with: item)
            rows.append(row)
        }
    }
    
    func numberOfRows() -> Int {
        let visibleRows = getVisibleRows()
        return visibleRows.count
    }
    
    func getVisibleRows() -> [ComposeFieldModel] {
        var visibleRows = [ComposeFieldModel]()
        for row in rows {
            switch row.display {
            case .always, .conditional:
                visibleRows.append(row)
            default:
                break
            }
        }
        return visibleRows
    }
    
    func getRow(at index: Int) -> ComposeFieldModel {
        let visibleRows = getVisibleRows()
        return visibleRows[index]
    }
}
