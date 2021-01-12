//: Core Data Model Mapping - Example to save or update models into core data models

import Foundation
import CoreData


//// Model Protocol
public protocol MessageModelProtocol {}


//// Core Data Protocol
public protocol RecordModelProtocol: NSObjectProtocol {
    
    func save<T: MessageModelProtocol>(_ model: T)
}


//// Regular Model
public class Account: MessageModelProtocol {
    
    var name: String!
    var id: Int!
}


//// Core Data Model
class CDAccount: NSManagedObject, RecordModelProtocol {

    var name: String!   //// TEMP: just to simulate core data model
    var id: Int!        //// TEMP: just to simulate core data model
    
    func save<T: MessageModelProtocol>(_ model: T) {
        //// Uncomment the following lines in your implementation [Playground can't support it ;)]
        
//      let cdmodel = CDAccount.create()
//      let mod = model as! Account
//      cdmodel.id = mod.id
//      cdmodel.name = mod.name
//      Record.save()
    }
    
}


//// Any model defined
let account = Account()
account.name = "Hello World"
account.id = 1

//// Here we map the model and save it into core data
let cdaccount = CDAccount()
cdaccount.save(account)


