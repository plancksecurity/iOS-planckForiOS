//
//  Capability.swift
//
//  Created by Yves Landert on 28.10.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import Contacts
import Photos


public struct Capability {
    
    public static let addressbook = AddressBook()
    public static let media = Media()
    
    public enum AccessError: Error {
        case notDetermined
        case restricted
        case denied
    }
    
    public class AddressBook {
        let contactStore = CNContactStore()
        
        func authorized(completion: @escaping (_ granted: Bool, _ error: AccessError?) -> (Void)) {
            let status = CNContactStore.authorizationStatus(for: .contacts)
            
            switch status {
            case .authorized:
                completion(true, nil)
                break
            case .denied, .notDetermined:
                contactStore.requestAccess(for: .contacts, completionHandler: { (access, error) in
                    if access {
                        completion(true, nil)
                    } else {
                        completion(false, .denied)
                    }
                })
                break
            case .restricted:
                completion(false, .restricted)
                break
            }
        }
    }
    
    public class Media {
        public final func authorized() -> Bool {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                return true
            case .denied, .notDetermined, .restricted:
                return false
            }
        }
        
        public final func request(completion: @escaping (_ granted: Bool, _ error: AccessError?) -> (Void)) {
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized:
                    completion(true, nil)
                    break
                case .denied, .notDetermined:
                    completion(false, .denied)
                    break
                case .restricted:
                    completion(false, .restricted)
                    break
                }
            }
        }
    }
}
