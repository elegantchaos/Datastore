//
//  File.swift
//  
//
//  Created by Developer on 20/12/2019.
//

import UIKit
import Datastore

public protocol DatastoreViewContextSupplier {
    var viewDatastore: Datastore { get }
}

extension UIViewController {
    func findStore() -> Datastore? {
        if let supplier = self as? DatastoreViewContextSupplier {
            return supplier.viewDatastore
        } else {
            return parent?.findStore()
        }
    }
}

extension UIView {
    func stickTo(view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
}
public class SelfSizingTable: UITableView {
    public override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

public class DatastoreIndexController: UIViewController {
    var table: UITableView!
    var datastore: Datastore?
    var items: [EntityReference] = []
    let labelKey: PropertyKey = .name
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        view.addSubview(stack)

        let label = UILabel()
        label.text = "Test"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.backgroundColor = .red
        stack.addArrangedSubview(label)

        table = SelfSizingTable()
        table.delegate = self
        table.dataSource = self
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        stack.addArrangedSubview(table)

        let label2 = UILabel()
        label2.text = "Another Test Which Is Long Enough To Wrap Around Onto A Second Line"
        label2.textAlignment = .center
        label2.numberOfLines = 0
        label2.sizeToFit()
        label2.lineBreakMode = .byWordWrapping
        label2.font = .systemFont(ofSize: 20)
        label2.backgroundColor = .red
        stack.addArrangedSubview(label2)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.stickTo(view: view)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        datastore = findStore()
        requestIndex()
    }
    
    func requestIndex() {
        if let store = datastore {
            store.getAllEntities() { results in
                store.get(properties: [self.labelKey], of: results) { items in
                    DispatchQueue.main.async {
                        self.items = items
                        self.table.reloadData()
                        self.table.invalidateIntrinsicContentSize()
                    }
                }
            }
        }
    }
}

extension DatastoreIndexController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let item = items[indexPath.row]
        cell.textLabel?.text = (item[labelKey] as? String) ?? "Unknown"
        return cell
    }
    
    
}

public class DatastoreEntityController: UIViewController {
    
}
