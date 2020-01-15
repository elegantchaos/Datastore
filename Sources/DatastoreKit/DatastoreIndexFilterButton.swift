// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import ViewExtensions

public class DatastoreIndexFilterButton: PopoverButton {
    class ItemTable: UITableViewController {
        let items: [String]
        
        init(items: [String]) {
            self.items = items
            super.init(style: .plain)
        }
        
        required init?(coder: NSCoder) {
            self.items = []
            super.init(coder: coder)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            let padding = CGFloat(16.0)
            let itemCount = self.tableView(tableView, numberOfRowsInSection: 0)
            let itemHeight = CGFloat(32.0)
            let height = padding + (CGFloat(itemCount + 1) * itemHeight)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "item")
            self.preferredContentSize = CGSize(width: 0, height: height)
            
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "item")!
            let index = indexPath.row
            if index < items.count {
                cell.textLabel?.text = items[index]
            }
            return cell
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            dismiss(animated: true) {
                
            }
        }
    }

    public convenience init() {
        self.init(viewConstructor: {
            return ItemTable(items: ["Foo", "Bar", "Fubar", "Wibble"])
        }, systemIconName: "line.horizontal.3.decrease.circle")
    }
    
}

//extension DatastoreIndexFilterButton: UIContextMenuInteractionDelegate {
//    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
//            return self.makeContextMenu()
//        })
//    }
//
//    func makeContextMenu() -> UIMenu {
//        // Create a UIAction for sharing
//          let share = UIAction(title: "Share Pupper", image: UIImage(systemName: "square.and.arrow.up")) { action in
//              // Show system share sheet
//          }
//
//          // Create and return a UIMenu with the share action
//          return UIMenu(title: "Main Menu", children: [share])
//    }
//
//}
