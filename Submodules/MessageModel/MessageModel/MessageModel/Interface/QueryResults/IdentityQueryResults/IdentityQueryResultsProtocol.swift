//
//  IdentityQueryResultsProtocol.swift
//  MessageModel
//
//  Created by Xavier Algarra on 08/10/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Provides a source to monitor identities in database that fit in the current search and informs it's delegate about.
/// changes (insert, update, move, delete) in the query's results.
/// This interface is an QueryResultrsController specified for Identities.
/// - seeAlso: QueryResultsControllerProtocol
/// - note: identities will be ordered alphabetically.
public protocol IdentityQueryResultsProtocol {

    /// Creates an IdentityQueryResultsController
    ///
    /// - Parameters:
    ///   - search: Used to search into de list of identities for those that fit in the search predicates.  subset of the results according to the
    ///   - delegate: Interface used to inform about the changes.
    init(search: IdentityQueryResultsSearch?, rowDelegate: QueryResultsIndexPathRowDelegate?,
    sectionDelegate: QueryResultsIndexPathSectionDelegate?)

    /// All row upadtes will be sent to this delegate (insert, update, move, delete) see QueryResultsDelegate to understand it behaviour.
    var sectionDelegate: QueryResultsIndexPathSectionDelegate? { set get }

    /// All section upadtes will be sent to this delegate (insert, update, move, delete) see QueryResultsDelegate to understand it behaviour.
    var rowDelegate: QueryResultsIndexPathRowDelegate? { set get }

    /// Current search (value found in the Address or name field). If no search is apply, search will be nil.
    var search: IdentityQueryResultsSearch? { get }

    /// Return a IdentityQueryResultsSectionProtocol that contains all the information for the asqued index.
    ///
    /// - Parameter index: index of desire section
    subscript(index: Int) -> IdentityQueryResultsSectionProtocol { get }

    /// - seeAlso:  doc in QueryResultrsControllerProtool startMonitoring function
    func startMonitoring() throws

    /// - seeAlso: doc in QueryResultrsControllerProtocol sectionIndexTitles
    var indexTitles: [String] { get }

    /// Number of sections, after applying search
    ///
    /// - Returns: number of identities, 0 if there is no section
    func count() -> Int
}

/// Provides all displayable information related to a sections of IdentityQueryResults
public protocol IdentityQueryResultsSectionProtocol {

    /// Name of the section
    var name: String { get }

    /// Title of the section (used when displaying the index)
    var title: String? { get }

    /// Number of objects in section
    var count: Int { get }

    var objects: [Identity] { get }

    /// Returns the array of objects in the section.
    subscript(index: Int) -> Identity { get }
}
