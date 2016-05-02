import Foundation
import CoreData

public protocol IFolder: _IFolder {
}

@objc(Folder)
public class Folder: _Folder, IFolder {
}
