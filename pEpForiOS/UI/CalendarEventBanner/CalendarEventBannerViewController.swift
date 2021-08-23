//
//  CalendarEventBannerViewController.swift
//  pEp
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class CalendarEventBannerViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var dayOfTheWeekLabel: UILabel!
    @IBOutlet private weak var dayNumberLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    public var viewModel: CalendarEventsBannerViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }
}

// MARK: - UITableViewDataSource

extension CalendarEventBannerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            //Valid case: the VM isn't loaded yet. 
            return 0
        }
        return vm.numberOfEvents
    }
}

// MARK: - UITableViewDelegate

extension CalendarEventBannerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventDescriptionTableViewCell.cellIdentifier, for: indexPath) as? CalendarEventDescriptionTableViewCell else {
            return UITableViewCell()
        }
        
        let event = vm.events[indexPath.row]
        let cellViewModel = ICSEventCellViewModel(event: event)
        cell.config(cellViewModel: cellViewModel, delegate: self)
        return cell
    }
}

// MARK: - Cell Delegate

extension CalendarEventBannerViewController: CalendarEventDescriptionTableViewCellDelegate {
    func didPressViewButton(event: ICSEvent) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleViewButtonTapped(event: event)
    }
}

// MARK: - Trait Collection

extension CalendarEventBannerViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                setup()
                view.layoutIfNeeded()
            }
        }
    }
}

//MARK: -  Private

extension CalendarEventBannerViewController {

    private func setup() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                view.backgroundColor = UIColor.pEpBannerGray
                titleLabel.textColor = .white
            } else {
                view.backgroundColor = UIColor.black
            }
        } else {
            view.backgroundColor = UIColor.black
        }
        guard let vm = viewModel, vm.numberOfEvents > 0 else {
            //Valid case. The view won't be visible.
            return
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 12
        titleLabel.text = vm.title
        dayNumberLabel.text = vm.dayNumber
        dayOfTheWeekLabel.text = vm.dayOfTheWeekLabel
        tableView.reloadData()
    }

    @IBAction private func closeButtonTapped() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleCloseButtonTapped()
    }

    private func calculatePreferredSize() {
        /// Expected banner height
        guard let vm = viewModel else {
            //Valid case: VM isn't setup yet. 
            return
        }
        let margin: CGFloat = vm.numberOfEvents > 1 ? 0.0 : 8.0
        let height = tableView.contentSize.height + titleLabel.frame.size.height + titleLabel.frame.origin.y + margin
        preferredContentSize = CGSize(width: view.bounds.width, height: height)
    }
}

