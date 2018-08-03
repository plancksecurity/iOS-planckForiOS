//
//  EmailListView+Prefetch.swift
//  pEp
//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailListViewController: UITableViewDataSourcePrefetching {


    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let prefetchViewModel =  model?.viewModel(for: indexPath.row)
            prefetchViewModel?.loadData()
            viewModels[indexPath] = prefetchViewModel
        }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            viewModels[indexPath]?.cancelLoad()
        }
    }

}
