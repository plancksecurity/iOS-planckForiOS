////
////  EmailFieldViewModel.swift
////  pEp
////
////  Created by Martin Brude on 09/09/2020.
////  Copyright © 2020 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//
//public struct EmailFieldViewModel : EmailFieldRowProtocol {
//    public var type: FieldViewModelType
//
//    /// Height of the field
//    public var height: CGFloat {
//        switch type {
//        case .from, .subject:
//            return 72.0
//        case .content, .attachment:
//            return 200.0
//        default:
//            return 0
//        }
//    }
//
//    /// Display type: always or conditional
//    public var display: FieldDisplayType {
//        switch type {
//        case .from, .subject, .content, .attachment:
//            return .always
//        default:
//            return .conditional
//        }
//    }
//    public var title : String {
//        switch type {
//        case .from:
//            return NSLocalizedString("From", comment: "")
//        case .subject:
//            return NSLocalizedString("Subject", comment: "")
//        case .content:
//            return NSLocalizedString("Content", comment: "")
//        default:
//            return ""
//        }
//    }
//
//    /// Row identifier
//    public var identifier: String {
//        switch type {
//        case .from:
//            return "senderCell"
//        case .subject:
//            return "senderSubjectCell"
//        case .content:
//            return "senderBodyCell"
//        case .attachment:
//            return "attachmentsCell"
//        default:
//            return ""
//        }
//    }
//}
//
///// Protocol that represents the basic data in a row.
//public protocol EmailFieldRowProtocol {
//    /// The type of the row
//    var type : FieldViewModelType { get }
//    /// The title of the row.
//    var title: String { get }
//    /// Returns the cell identifier
//    var identifier: String { get }
//    /// Returns the cell height
//    var height: CGFloat { get }
//}
