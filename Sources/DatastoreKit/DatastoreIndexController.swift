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
    var filter: String?
    var sortAscending = true
    var addSortButton = true
    
    var tableView: UITableView!
    var searchBar: UISearchBar!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(axis: .vertical)
        view.addSubview(stack)
        stack.stickTo(view: view)

        let table = EnhancedTableView()
        table.delegate = self
        table.dataSource = self
        self.tableView = table
        stack.addArrangedSubview(table)

        setupFooter()
        
//        let label2 = UILabel()
//        label2.text = "Another Test Which Is Long Enough To Wrap Around Onto A Second Line"
//        label2.textAlignment = .center
//        label2.numberOfLines = 0
//        label2.sizeToFit()
//        label2.lineBreakMode = .byWordWrapping
//        label2.font = .systemFont(ofSize: 20)
//        label2.backgroundColor = .red
//        stack.addArrangedSubview(label2)
    }
    
    func setupFooter() {
        let stack = UIStackView(axis: .horizontal, alignment: .center)

        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
//        searchBar.showsSearchResultsButton = true
//        searchBar.showsBookmarkButton = true
        searchBar.isHidden = true
        stack.addArrangedSubview(searchBar)
        self.searchBar = searchBar
        
        let spacer = UIView(frame: .zero)
        //        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(spacer)
        
        let filterButton = DatastoreIndexFilterButton()
        stack.addArrangedSubview(filterButton)
        
        let searchButton = DatastoreIndexSearchButton(index: self)
        stack.addArrangedSubview(searchButton)
        
        if addSortButton {
            let sortButton = DatastoreIndexSortButton(index: self)
            stack.addArrangedSubview(sortButton)
        }
        
        stack.sizeToFit()
        tableView.tableFooterView = stack
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
    
    func toggleSearchBar() {
        searchBar.isHidden = !searchBar.isHidden
        if searchBar.isHidden {
            searchBar.resignFirstResponder()
        } else {
            searchBar.becomeFirstResponder()
        }

        view.setNeedsLayout()
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.setNeedsLayout()
        tableView.setNeedsUpdateConstraints()
    }
    
    func filter(items: [EntityReference]) -> [EntityReference] {
        guard let filter = filter, filter.count > 0 else {
            return items
        }
        
        return items.filter({
            if let string = $0[labelKey] as? String {
                return string.contains(filter)
            } else {
                return false
            }
        })
    }
        
    func requestIndex() {
        if let store = datastore {
            store.getAllEntities() { results in
                store.get(properties: [self.labelKey], of: results) { items in
                    DispatchQueue.main.async {
                        let filtered = self.filter(items: items)
                        let sorted = filtered.sorted { (i1, i2) -> Bool in
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

extension DatastoreIndexController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter = searchText
        requestIndex()
        if searchText.isEmpty {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search button")
    }
    
    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        print("results list")
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel")
    }
    
    public func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        print("bookmark")
    }
}

