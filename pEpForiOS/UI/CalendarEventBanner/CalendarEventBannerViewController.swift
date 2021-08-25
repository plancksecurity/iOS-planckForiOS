//
//  CalendarEventBannerViewController.swift
//  pEp
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import EventKit
import EventKitUI

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
            // Valid case: The storyboard intanciates the VC before we have the chance to set a VM.
            return 0
        }
        return vm.numberOfEvents
    }

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

// MARK: - UITableViewDelegate

extension CalendarEventBannerViewController: UITableViewDelegate { }

extension CalendarEventBannerViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}
// MARK: - Cell Delegate

extension CalendarEventBannerViewController: CalendarEventDescriptionTableViewCellDelegate {
    func didPressViewButton(event: ICSEvent) {
        UIUtils.presentEditEventCalendarView(event: event, eventEditViewDelegate: self, delegate: self) { [weak self] eventDetailPresentationResult in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            switch eventDetailPresentationResult {
            case .success:
                Log.shared.info("The calendar view was succesfully presented. Nothing to do")
            case .failure(let error):
                me.showErrorAlert(error: error)
            }
        } addEventCallback: { [weak self] addEventResult in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            switch addEventResult {
            case .success:
                Log.shared.info("An Event was successfully added. Nothing to do")
            case .failure(let error):
                me.showErrorAlert(error: error)
            }
        }
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


// MARK: - UINavigationControllerDelegate

extension CalendarEventBannerViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        /// EKEventEditViewController contains a table view that behaves buggy when scrolling.
        /// The background color of the cells that are dequeued again changes  for no reason.
        /// This workaround prevents a wrong layout.
        if let tableViewController = viewController as? UITableViewController {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .light {
                    tableViewController.view.backgroundColor = UIColor.white
                    tableViewController.tableView.backgroundColor = UIColor.white
                } else {
                    tableViewController.view.backgroundColor = UIColor.secondarySystemBackground
                    tableViewController.tableView.backgroundColor = UIColor.secondarySystemBackground
                }
            } else {
                tableViewController.view.backgroundColor = UIColor.white
                tableViewController.tableView.backgroundColor = UIColor.white
            }
            tableViewController.tableView.backgroundView = .none	
        }
    }
}

//MARK: -  Private

extension CalendarEventBannerViewController {

    private func setup() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                view.backgroundColor = UIColor.pEpBackgroundGray2
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

    private func showErrorAlert(error: EKEventStoreUtil.CalendarError) {
        UIUtils.showTwoButtonAlert(withTitle:  NSLocalizedString("Error", comment: "Error title"),
                                   message: error.errorDescription,
                                   cancelButtonText: NSLocalizedString("Cancel", comment: "Cancel - button title"),
                                   positiveButtonText: NSLocalizedString("Settings", comment: "Settings - button title"),
                                   cancelButtonAction: { [weak self] in
                                    guard let me = self else {
                                        Log.shared.errorAndCrash("Lost myself")
                                        return
                                    }
                                    me.showSettings()
                                   }, positiveButtonAction: { })
    }

    private func showSettings() {
        UIUtils.openSystemSettings()
    }
}
