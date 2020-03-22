//
//  ContentView.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 3/22/20.
//  Copyright © 2020 truman. All rights reserved.
//

import SwiftUI
import Combine
import CSV

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
    /*A subject that broadcasts elements to downstream subscribers.*/
    var filename: String
    var changed = PassthroughSubject<[Item],Never>()

    func changeData() {
        DispatchQueue.global().async {
            let stream = InputStream(fileAtPath: Bundle.main.path(forResource: self.filename, ofType: "csv")!)!
            let csv = try! CSVReader(stream: stream, hasHeaderRow: true)
            var items = [Item]()
            while csv.next() != nil {
                let item = Item(name: csv["Name"]!,
                                seasonality: csv["Seasonality"]!,
                                location: csv["Name"]!,
                                time: csv["Time"]!,
                                price: Int(csv["Price"]!)!,
                                found: Defaults.isFound(csv["Name"]!)
                )
                items.append(item)
            }
            DispatchQueue.main.async {
                self.changed.send(items)
            }
        }
    }

    func sort(_ items: [Item], sortOption: SortOption) {
        switch sortOption {
        case .price:
            self.changed.send(items.sorted(by: \.price).reversed() )
        case .aToZ:
            self.changed.send(items.sorted(by: \.name))
        }
    }

    func filter(_ items: [Item], hideFound: Bool) {
        if !hideFound {
            changeData()
            return
        }
        self.changed.send(items.filter {
            return $0.found == false
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

struct ContentView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            BugList()
            .tabItem {
                VStack {
                    Image("first")
                    Text("Bugs")
                }
            }
            .tag(0)
            FishList()
            .tabItem {
                VStack {
                    Image("second")
                    Text("Fish")
                }
            }
            .tag(1)
        }
    }
}

class ToggleModel: ObservableObject {
    var hideFound = false {
        didSet {
            changed.send(hideFound)
        }
    }

    var changed = PassthroughSubject<Bool,Never>()
}

struct BugList: View {
    @State var bugs = [Item]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false

    var presenter = Presenter(filename: "bugs")

    var body: some View {
        NavigationView {
            List(bugs) { bug in
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(bug.name)
                        Text("\(bug.price)")
                    }
                    Spacer()
                    if bug.found {
                        Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20.0))
                        .foregroundColor(.green)
                    }
                }
                .contextMenu {
                    Button(action: {
                        Defaults.setFound(bug.name, isFound: !bug.found)
                        self.presenter.changeData()
                    }, label: {
                        Text("Mark as Found")
                    })
                }
            }
            .onAppear() {
                self.presenter.changeData()
            }.onReceive(presenter.changed) { (output) in
                self.bugs = output
            }.onReceive(hideFound.changed) { (output) in
                self.presenter.filter(self.bugs, hideFound: output)
            }.navigationBarTitle("Bugs")
            .navigationBarItems(leading:
                Toggle(isOn: $hideFound.hideFound, label: { Text("Hide Found") }), trailing:
            Button(action: {
                self.showingSheet = true
            }, label: {
                Text("Sort")
            }).actionSheet(isPresented: $showingSheet) {
                ActionSheet(title: Text("Sort Bugs"), buttons: [
                    .default(Text("Price"), action: {
                        self.presenter.sort(self.bugs, sortOption: .price)
                }), .default(Text("A-Z"), action: {
                    self.presenter.sort(self.bugs, sortOption: .aToZ)
                }), .cancel()])
                }
            )
        }
    }
}

struct FishList: View {
    @State var fish = [Item]()
    var presenter = Presenter(filename: "fish")

    var body: some View {
        NavigationView {
            List(fish) { fish in
                Text(fish.name)
            }
            .onAppear() {
                self.presenter.changeData()
            }.onReceive(presenter.changed) { (output) in
                self.fish = output
            }.navigationBarTitle("Fish")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
