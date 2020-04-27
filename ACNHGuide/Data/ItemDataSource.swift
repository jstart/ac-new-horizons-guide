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

struct AltItem: Codable {
    let id: Int
    let fileName: String
    let price: Int
    let catchPhrase: String
    let museumPhrase: String
    let availability: Availability
    let name: Name
//    let shadow: String

    enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file-name"
        case price
        case catchPhrase = "catch-phrase"
        case museumPhrase = "museum-phrase"
        case availability
        case name
//        case shadow
    }

    var nameString: String {
        let id = Locale.current.identifier
        switch id {
        case "en_US":
            return name.name_en
        default:
            return ""
        }
    }
}

struct Availability: Codable {
    let monthNorthern: String
    let monthSouthern: String
    let time: String
    let isAllDay: Bool
    let isAllYear: Bool
    let location: String
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case monthNorthern = "month-northern"
        case monthSouthern = "month-southern"
        case time
        case isAllDay
        case isAllYear
        case location
        case rarity
    }

    var availabilityText: String {
        var text = "Availability: "
        if isAllDay {
            text += "All Day, "
        } else {
            text += "\(time), "
        }

        if isAllYear {
            text += "All Year"
        } else {
            text += monthNorthern
        }
        return text
    }

    var monthNorthernText: String {
        let months = monthNorthern.split(separator: "-")
        let df = DateFormatter()
        let first = df.monthSymbols[Int("\(months.first!)")! - 1]
        let second = df.monthSymbols[Int("\(months.last!)")! - 1]
        return "\(first) - \(second)"
    }
}

struct Name: Codable {
    let name_cn: String
    let name_de: String
    let name_en: String
    let name_fr: String
    let name_it: String
    let name_jp: String
    let name_kr: String
    let name_nl: String
    let name_ru: String

    enum CodingKeys: String, CodingKey {
        case name_cn = "name-cn"
        case name_de = "name-de"
        case name_en = "name-en"
        case name_fr = "name-fr"
        case name_it = "name-it"
        case name_jp = "name-jp"
        case name_kr = "name-kr"
        case name_nl = "name-nl"
        case name_ru = "name-ru"

    }
}

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
    var altChanged = PassthroughSubject<[AltItemViewModel],Never>()

    func changeAltData() {
        DispatchQueue.global().async {
            guard let filePath = Bundle.main.path(forResource: self.filename, ofType: "json") else { return }
            guard let jsonData = FileManager.default.contents(atPath: filePath) else { return }

            do {
                let items = try JSONDecoder().decode([String: AltItem].self, from: jsonData)
            } catch {
                print(error)
            }
            guard let items = try? JSONDecoder().decode([String: AltItem].self, from: jsonData) else { return }
            let itemModels = items.map { AltItemViewModel(item: $0.value) }
            DispatchQueue.main.async {
                self.altChanged.send(itemModels)
            }
        }
    }

    func changeData() {
        DispatchQueue.global().async {
            let stream = InputStream(fileAtPath: Bundle.main.path(forResource: self.filename, ofType: "csv")!)!
            let csv = try! CSVReader(stream: stream, hasHeaderRow: true)
            var items = [ItemViewModel]()
            while csv.next() != nil {
                let item = Item(name: csv["Name"]!,
                                seasonality: csv["Seasonality"]!,
                                location: csv["Location"]!,
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
