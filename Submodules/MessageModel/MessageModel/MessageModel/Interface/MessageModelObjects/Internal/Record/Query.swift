//
// Query.swift
//
// Copyright (c) 2014-2016 appculture AG http://appculture.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import CoreData

import pEpIOSToolbox

//!!!: review, cleanup, move

/**
 This extension of `NSManagedObject` is all about easy querying.

 All queries are called as class functions on any object that is kind of `NSManagedObject`,
 and `Record.Context.default` is used if you don't specify any custom.
 */
public extension NSManagedObject {

    // MARK: - General

    /**
     This property must return correct entity name because it's used all across other helpers
     to reference custom `NSManagedObject` subclass.

     You may override this property in your custom `NSManagedObject` subclass if needed,
     but it should work 'out of the box' generally.
     */
    static var entityName: String {
        var name = NSStringFromClass(self)
        name = name.components(separatedBy: ".").last!
        return name
        //!!!: fix test setup to not create multiple in-memory- stores per test suite
//        guard let entityName = entity().name else {
//            fatalError("Entity without name!")
//        }
//        return entityName
    }

    /**
     Creates fetch request for any entity type with given predicate (optional) and sort descriptors (optional).

     - parameter predicate: Predicate for fetch request.
     - parameter sortDescriptors: Sort Descriptors for fetch request.

     - returns: The created fetch request.
     */
    class func createFetchRequest<T: NSManagedObject>(predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }

    func execute<T: NSManagedObject>(fetchRequest request: NSFetchRequest<T>,
                                     in context: NSManagedObjectContext) -> [T] {
        var fetchedObjects = [T]()
        context.performAndWait {
            do {
                fetchedObjects = try context.fetch(request)
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        }
        return fetchedObjects
    }

    static let defaultPredicateType: NSCompoundPredicate.LogicalType = .and

    /**
     Finds the first record. Generic version.

     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional instance of `Self`.
     */
    private class func _first<T>(sortDescriptors: [NSSortDescriptor]? = nil,
                              in context: NSManagedObjectContext) -> T? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        request.fetchLimit = 1

        let objects = execute(fetchRequest: request, in: context)
        return objects.first as? T
    }

    /**
     Finds the first record for given predicate.

     - parameter predicate: Predicate.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    class func first(predicate: NSPredicate,
                     orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext) -> Self? {
        return _first(predicate: predicate, orderedBy: sortDescriptors, in: context)
    }

    /**
     Finds the first record for given predicate. Generic version

     - parameter predicate: Predicate.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional instance of `Self`.
     */
    private class func _first<T>(predicate: NSPredicate,
                                 orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                                 in context: NSManagedObjectContext) -> T? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        request.fetchLimit = 1

        let objects = execute(fetchRequest: request, in: context)
        return objects.first as? T
    }

    // MARK: - Find All

    /**
     Finds all records.

     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    class func all(sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext) -> [NSManagedObject]? {
        let request = createFetchRequest(sortDescriptors: sortDescriptors)
        let objects = execute(fetchRequest: request, in: context)
        return objects.count > 0 ? objects : nil
    }

    /**
     Finds all records. Generic version.

     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional array of `Self` instances.
     */
    class func all<T>(sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext) -> [T]? {
        let objects = all(sortDescriptors: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }

    /**
     Finds all records for given predicate.

     - parameter predicate: Predicate.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    class func all(predicate: NSPredicate,
                   orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext) -> [NSManagedObject]? {
        let request = createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)
        let objects = execute(fetchRequest: request, in: context)
        return objects.count > 0 ? objects : nil
    }

    /**
     Finds all records for given predicate. Generic version

     - parameter predicate: Predicate.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional array of `Self` instances.
     */
    class func all<T:NSManagedObject>(predicate: NSPredicate,
                                      orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                                      in context: NSManagedObjectContext) -> [T]? {
        let objects = all(predicate: predicate, orderedBy: sortDescriptors, in: context)
        return objects?.map { $0 as! T }
    }
}

// MARK: - Private

extension NSManagedObject {

    private class func execute<T: NSManagedObject>(fetchRequest request: NSFetchRequest<T>,
                                     in context: NSManagedObjectContext) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
        return []
    }
}

// MARK: - Deprecated

extension NSManagedObject {
    /**
     Creates predicate for given attributes and predicate type.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.and` will be used.

     - returns: The created predicate.
     */
    @available(*, deprecated, message: "Create or reuse Predicate Factory instead")
    class func createPredicate(attributes: [AnyHashable : Any], //!!!: rm and fix usage
        predicateType: NSCompoundPredicate.LogicalType = NSManagedObject.defaultPredicateType) -> NSPredicate {

        var predicates = [NSPredicate]()
        for (attribute, value) in attributes {
            predicates.append(NSPredicate(format: "%K = %@", argumentArray: [attribute, value]))
        }
        let compoundPredicate = NSCompoundPredicate(type: predicateType, subpredicates: predicates)
        return compoundPredicate
    }

    // MARK: - Create

    /**
     Creates new instance of entity object.

     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: New instance of `Self`.
     */
    //!!!: must go away. (or highly improve)
    @available(*, deprecated, message: "Use CdObject(context:NSManagedContext) instead")
    @discardableResult private class func create(context: NSManagedObjectContext) -> Self {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let object = self.init(entity: entityDescription, insertInto: context)
        return object
    }

    /**
     Creates new instance of entity object and configures it with given attributes.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: New instance of `Self` with set attributes.
     */
    @available(*, deprecated, message: "Use CdObject(context:NSManagedContext) instead")
    @discardableResult class func create(attributes: [String : Any],
                                         in context: NSManagedObjectContext) -> Self {
        let object = create(context:context)
        if attributes.count > 0 {
            object.setValuesForKeys(attributes)
        }
        return object
    }

    // MARK: - Find First or Create

    /**
     Finds the first record for given attribute and value or creates new if it does not exist.

     - parameter attribute: Attribute name.
     - parameter value: Attribute value.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Instance of managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class func firstOrCreate(attribute: String, value: Any,
                             in context: NSManagedObjectContext) -> Self {
        return _firstOrCreate(attribute: attribute, value: value, in: context)
    }

    /**
     Finds the first record for given attribute and value or creates new if it does not exist. Generic version.

     - parameter attribute: Attribute name.
     - parameter value: Attribute value.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Instance of `Self`.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    private class func _firstOrCreate<T>(attribute: String,
                                         value: Any,
                                         in context: NSManagedObjectContext) -> T {
        let object = firstOrCreate(attributes: [attribute : value], in: context)
        return object as! T
    }

    /**
     Finds the first record for given attributes or creates new if it does not exist.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.AndPredicateType` will be used.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Instance of managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class func firstOrCreate(attributes: [String : Any],
                             predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                             in context: NSManagedObjectContext) -> Self {
        return _firstOrCreate(attributes: attributes, predicateType: predicateType, in: context)
    }

    /**
     Finds the first record for given attributes or creates new if it does not exist. Generic version.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.AndPredicateType` will be used.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Instance of `Self`.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    private class func _firstOrCreate<T>(attributes: [String : Any],
                                         predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                                         in context: NSManagedObjectContext) -> T {
        let predicate = createPredicate(attributes: attributes, predicateType: predicateType)
        let request = createFetchRequest(predicate: predicate)
        request.fetchLimit = 1
        let objects = execute(fetchRequest: request, in: context)
        return (objects.first ?? create(attributes: attributes, in: context)) as! T
    }

    // MARK: - Find First

    ///Finds the first record.
    ///
    /// - parameter sortDescriptors: Sort descriptors.
    /// - parameter context: If not specified, `Record.Context.default` will be used.
    ///
    /// - returns: Optional managed object.
    @available(*, deprecated, message: "Dont")
    class func first(sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext) -> Self? {
        return _first(sortDescriptors: sortDescriptors, in: context)
    }

    /**
     Finds all records for given attribute and value.

     - parameter attribute: Attribute name.
     - parameter value: Attribute value.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class private func all(attribute: String,
                           value: Any,
                           orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                           in context: NSManagedObjectContext) -> [NSManagedObject]? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return all(predicate: predicate, orderedBy: sortDescriptors, in: context)
    }

    /**
     Finds all records for given attributes.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.AndPredicateType` will be used.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")//!!!: move to test target
    class func all(attributes: [AnyHashable : Any],
                   predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                   orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                   in context: NSManagedObjectContext) -> [NSManagedObject]? {
        let predicate = createPredicate(attributes: attributes, predicateType: predicateType)
        return all(predicate: predicate, orderedBy: sortDescriptors, in: context)
    }

    /**
     Finds all records for given attributes. Generic version.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.AndPredicateType` will be used.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional array of `Self` instances.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class func all<T>(attributes: [AnyHashable : Any],
                      predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                      orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                      in context: NSManagedObjectContext) -> [T]? {
        let objects = all(attributes: attributes,
                          predicateType: predicateType,
                          orderedBy: sortDescriptors,
                          in: context)
        return objects?.map { $0 as! T }
    }

    /**
     Finds the first record for given attribute and value.

     - parameter attribute: Attribute name.
     - parameter value: Attribute value.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class func first(attribute: String, value: Any, orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext) -> Self? {
        let predicate = NSPredicate(format: "%K = %@", argumentArray: [attribute, value])
        return first(predicate: predicate, orderedBy: sortDescriptors, in: context)
    }

    /**
     Finds the first record for given attributes.

     - parameter attributes: Dictionary of attribute names and values.
     - parameter predicateType: If not specified, `.AndPredicateType` will be used.
     - parameter sortDescriptors: Sort descriptors.
     - parameter context: If not specified, `Record.Context.default` will be used.

     - returns: Optional managed object.
     */
    @available(*, deprecated, message: "Use the version with predicate instead.")
    class func first(attributes: [AnyHashable : Any],
                     predicateType: NSCompoundPredicate.LogicalType = defaultPredicateType,
                     orderedBy sortDescriptors: [NSSortDescriptor]? = nil,
                     in context: NSManagedObjectContext? = nil) -> Self? {
        let moc: NSManagedObjectContext = context ?? Stack.shared.mainContext
        let predicate = createPredicate(attributes: attributes, predicateType: predicateType)
        return first(predicate: predicate, orderedBy: sortDescriptors, in: moc)
    }
}
