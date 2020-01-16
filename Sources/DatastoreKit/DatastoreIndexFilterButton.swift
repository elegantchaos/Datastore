// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import ViewExtensions

public class DatastoreIndexFilterButton: PopoverMenuButton {
    public convenience init() {
        self.init(
            items: ["Foo", "Bar", "Fubar", "Wibble"],
            systemIconName: "line.horizontal.3.decrease.circle",
            onSelect: { item in
                print("selected \(item)")
        })
    }
    
}
