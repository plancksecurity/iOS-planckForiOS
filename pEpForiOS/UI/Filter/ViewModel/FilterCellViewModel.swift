
import Foundation
import MessageModel

public class FilterCellViewModel {

    var icon: UIImage?
    var title: String
    var enabled: Bool

    public init(image: UIImage, title: String, enabled: Bool? = false) {
        self.icon = image
        self.title = title
        if let filterEnabled = enabled {
            self.enabled = filterEnabled
        } else {
            self.enabled = false
        }
    }

}
