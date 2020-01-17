// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import ViewExtensions
import Datastore

public class DatastoreIndexFilterButton: PopoverMenuButton {
    public convenience init(forTypes entityTypes: [EntityType]) {
        var items = ["All", "-"]
        items.append(contentsOf: entityTypes.map { $0.name })
        self.init(
            items: items,
            systemIconName: "line.horizontal.3.decrease.circle"
        )
    }
    
    override open func select(item: MenuItem) {
        if let controller = self.findViewController() as? DatastoreIndexController, let string = item as? String {
            if string == "All" {
                controller.clearFilter()
            } else {
                controller.filter(by: EntityType(string))
            }
        }
    }
}
