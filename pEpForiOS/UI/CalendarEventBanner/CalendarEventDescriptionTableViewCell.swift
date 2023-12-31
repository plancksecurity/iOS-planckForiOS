//
//  CalendarEventDescriptionTableViewCell.swift
//  pEp
//
//  Created by Martín Brude on 23/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox

protocol CalendarEventDescriptionTableViewCellDelegate: AnyObject {
    /// Communicate the view button has been pressed
    /// - Parameter event: The event of the view that was pressed
    func didPressViewButton(event: ICSEvent)
}

class CalendarEventDescriptionTableViewCell: UITableViewCell {
    public static let cellIdentifier = "calendarEventDescriptionCell"

    private weak var delegate: CalendarEventDescriptionTableViewCellDelegate?

    @IBOutlet private weak var eventDescriptionLabel: EdgeInsetLabel!

    private var cellViewModel: ICSEventCellViewModel?

    public func config(cellViewModel: ICSEventCellViewModel, delegate: CalendarEventDescriptionTableViewCellDelegate) {
        self.delegate = delegate
        self.cellViewModel = cellViewModel
        self.eventDescriptionLabel.text = cellViewModel.datetimeDescription

        //Force to layout to get correct height
        if UITraitCollection.current.userInterfaceStyle == .dark {
            contentView.backgroundColor = UIColor.pEpBackgroundGray2
            eventDescriptionLabel.textColor = UIColor.white
        } else {
            contentView.backgroundColor = UIColor.black
        }

        self.eventDescriptionLabel.sizeToFit()
        self.eventDescriptionLabel.layoutIfNeeded()
    }

    @IBAction public func viewButtonPressed() {
        guard let event = cellViewModel?.event else {
            Log.shared.errorAndCrash("Event not found")
            return
        }
        delegate?.didPressViewButton(event: event)
    }
}
