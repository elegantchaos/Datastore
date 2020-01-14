// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Datastore
import LayoutExtensions
import ViewExtensions

public class DatastoreIndexController: UIViewController {
    var datastore: Datastore?
    var items: [EntityReference] = []
    var labelKey: PropertyKey = .name
    var sortingKeys: [PropertyKey] = [.name]
    var sortAscending = true
    var addSortButton = true
    var searchController: UISearchController? = nil
    var tableView: UITableView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        view.addSubview(stack)

        let table = EnhancedTableView()
        table.delegate = self
        table.dataSource = self
        self.tableView = table
        stack.addArrangedSubview(table)

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.sizeToFit()
        self.searchController = searchController
        
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.showsSearchResultsButton = true
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .bottom
        headerStack.distribution = .fill
        headerStack.addArrangedSubview(searchController.searchBar)

        if addSortButton {
            let sortButton = DatastoreIndexSortButton(index: self)
            headerStack.addArrangedSubview(sortButton)
        }


        headerStack.sizeToFit()
        table.tableHeaderView = headerStack

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
        
    func toggleSortDirection() {
        sortAscending = !sortAscending
        requestIndex()
    }
    
    func requestIndex() {
        if let store = datastore {
            store.getAllEntities() { results in
                store.get(properties: [self.labelKey], of: results) { items in
                    DispatchQueue.main.async {
                        let sorted = items.sorted { (i1, i2) -> Bool in
                            for key in self.sortingKeys {
                                if let s1 = i1[key] as? String, let s2 = i2[key] as? String {
                                    if s1 < s2 {
                                        return self.sortAscending
                                    } else if s2 < s1 {
                                        return !self.sortAscending
                                    }
                                }
                            }
                            return false
                        }
                        self.items = sorted
                        self.tableView.reloadData()
                        self.tableView.invalidateIntrinsicContentSize()
                    }
                }
            }
        }
    }
}

extension DatastoreIndexController: UITableViewDelegate, UITableViewDataSource {
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

extension DatastoreIndexController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        
    }
}
