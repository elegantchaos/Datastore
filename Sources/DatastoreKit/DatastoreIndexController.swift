// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore
import LayoutExtensions
import ViewExtensions

public class DatastoreIndexController: UIViewController {
    public typealias SelectionHandler = (EntityReference) -> (Bool)

    // MARK: Configuration Properties
    public var labelKey: PropertyKey = .name
    public var sortingKeys: [PropertyKey] = [.name]
    public var filterTypes: [EntityType] = []
    public var onSelect: SelectionHandler?
    public var showFooter = true
    
    // MARK: Private Properties
    
    var datastore: Datastore?
    var items: [EntityReference] = []
    
    var filterString: String?
    var filterType: EntityType?
    var sortAscending = true
    var addSortButton = true
    var selfSizing = false
    
    var rootStack: UIStackView!
    var tableView: UITableView!
    var searchBar: UISearchBar!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = DatastoreKit.spacing
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.stickTo(view: view)
        rootStack = stack
        
        let table = EnhancedTableView()
        table.selfSizing = selfSizing
        table.delegate = self
        table.dataSource = self
        self.tableView = table
        stack.addArrangedSubview(table)

        if showFooter {
            setupFooter()
        }
    }
    
    func setupFooter() {
        let stack = UIStackView(axis: .horizontal, alignment: .center)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins.trailing = DatastoreKit.spacing
        
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.isHidden = true
        stack.addArrangedSubview(searchBar)
        self.searchBar = searchBar
        
        let spacer = UIView(frame: .zero)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(spacer)
        
        let searchButton = DatastoreIndexSearchButton(index: self)
        stack.addArrangedSubview(searchButton)
        
        if filterTypes.count > 0 {
            let filterButton = DatastoreIndexFilterButton(index: self, forTypes: filterTypes)
            stack.addArrangedSubview(filterButton)
        }
        
        if addSortButton {
            let sortButton = DatastoreIndexSortButton(index: self)
            stack.addArrangedSubview(sortButton)
        }
        
        stack.sizeToFit()
        rootStack.addArrangedSubview(stack)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if datastore == nil {
            datastore = findStore()
            requestIndex()
        }
    }
        
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
    
    public func toggleFilter(for type: EntityType) {
        if filterType == type {
            filterType = nil
        } else {
            filterType = type
        }
        requestIndex()
    }
    
    func filterByString(items: [EntityReference]) -> [EntityReference] {
        guard let filter = filterString, !filter.isEmpty else {
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
    
    func filterByType(items: [EntityReference]) -> [EntityReference] {
        guard let type = filterType else {
            return items
        }
        
        return items.filter({ $0.type == type })
    }
    
    func requestIndex() {
        if let store = datastore {
            store.getAllEntities() { results in
                store.get(properties: [self.labelKey], of: results) { items in
                    DispatchQueue.main.async {
                        let filteredForType = self.filterByType(items: items)
                        let filteredForTypeAndString = self.filterByString(items: filteredForType)
                        let sorted = filteredForTypeAndString.sorted { (i1, i2) -> Bool in
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
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if let resetSelection = onSelect?(item), resetSelection {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension DatastoreIndexController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterString = searchText
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
#endif
