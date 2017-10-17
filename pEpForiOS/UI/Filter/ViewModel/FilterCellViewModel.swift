
import Foundation
import MessageModel

public class FilterCellViewModel {

    var icon: UIImage?
    var title: String
    var enabled: Bool
    var filter: FilterBase

    public init(image: UIImage, title: String, enabled: Bool = false, filter: FilterBase) {
        self.icon = image
        self.title = title
        self.enabled = enabled
        self.filter = filter
    }

}
