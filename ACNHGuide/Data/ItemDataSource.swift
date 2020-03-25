//
//  ItemDataSource.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 3/22/20.
//  Copyright © 2020 truman. All rights reserved.
//

import Combine
import CSV
import Foundation

struct Item: Identifiable {
    let id = UUID()

    var name: String
    var seasonality: String
    var location: String
    var time: String
    var price: Int

    var found: Bool
}

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}

struct Presenter {
    enum SortOption {
        case price
        case aToZ
    }
    var filename: String
    var changed = PassthroughSubject<[ItemViewModel],Never>()

    func changeData() {
        DispatchQueue.global().async {
            let stream = InputStream(fileAtPath: Bundle.main.path(forResource: self.filename, ofType: "csv")!)!
            let csv = try! CSVReader(stream: stream, hasHeaderRow: true)
            var items = [ItemViewModel]()
            while csv.next() != nil {
                let item = Item(name: csv["Name"]!,
                                seasonality: csv["Seasonality"]!,
                                location: csv["Name"]!,
                                time: csv["Time"]!,
                                price: Int(csv["Price"]!)!,
                                found: Defaults.isFound(csv["Name"]!)
                )
                items.append(ItemViewModel(item: item))
            }
            DispatchQueue.main.async {
                self.changed.send(items)
            }
        }
    }

    func sort(_ items: [ItemViewModel], sortOption: SortOption) {
        switch sortOption {
        case .price:
            self.changed.send(items.sorted(by: \.item.price).reversed() )
        case .aToZ:
            self.changed.send(items.sorted(by: \.item.name))
        }
    }

    func filter(_ items: [ItemViewModel], hideFound: Bool) {
        if !hideFound {
            changeData()
            return
        }
        self.changed.send(items.filter {
            return $0.item.found == false
        })
    }
}

struct Defaults {
    static func setFound(_ name: String, isFound: Bool) {
        UserDefaults.standard.set(isFound, forKey: name)
    }

    static func isFound(_ name: String) -> Bool {
        return UserDefaults.standard.bool(forKey: name)
    }
}
