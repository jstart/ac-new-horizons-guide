//
//  ContentView.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 3/22/20.
//  Copyright © 2020 truman. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            BugList()
            .tabItem {
                VStack {
                    Image(systemName: "ant")
                    Text("Bugs")
                }
            }
            .tag(0)
            FishList()
            .tabItem {
                VStack {
                    Image(systemName: "tortoise")
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

class ItemViewModel: ObservableObject, Identifiable {
    var id = UUID()
    var changed = PassthroughSubject<Item,Never>()
    var item: Item

    init(item: Item) {
        self.item = item
    }
}

struct ItemView: View {
    @State var viewModel: ItemViewModel
    @State var item: Item

    var body: some View {
        HStack {
            HStack {
                Image(item.name)
                .frame(width: 64, height: 64, alignment: .center)
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.name)
                    Text("\(item.price) Bells, Available: \(item.time), \(item.seasonality)")
                }
            }
            Spacer()
            if item.found {
                Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20.0))
                .foregroundColor(.green)
            }
        }.onReceive(viewModel.changed, perform: { (output) in
            self.viewModel.item = output
            self.item = output
        }).contentShape(Rectangle())
    }
}

struct BugList: View {
    @State var bugs = [ItemViewModel]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false

    var presenter = Presenter(filename: "bugs")

    var body: some View {
        NavigationView {
            List(bugs) { bug in
                ItemView(viewModel: bug, item: bug.item)
                .onTapGesture {
                    Defaults.setFound(bug.item.name, isFound: !bug.item.found)
                    bug.item.found.toggle()
                    bug.changed.send(bug.item)
                }
                .contextMenu {
                    Button(action: {
                        Defaults.setFound(bug.item.name, isFound: !bug.item.found)
                        bug.item.found.toggle()
                        bug.changed.send(bug.item)
                    }, label: {
                        Text("Mark as Found")
                    })
                }
            }
            .onAppear() {
                if self.bugs.count > 0 {
                    return
                }
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
                }.scaledToFill()
            )
        }.phoneOnlyStackNavigationView()
    }
}

struct FishList: View {
    @State var fish = [ItemViewModel]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false

    var presenter = Presenter(filename: "fish")

    var body: some View {
        NavigationView {
            List(fish) { fish in
                ItemView(viewModel: fish, item: fish.item)
                .onTapGesture {
                    Defaults.setFound(fish.item.name, isFound: !fish.item.found)
                    fish.item.found.toggle()
                    fish.changed.send(fish.item)
                }
                .contextMenu {
                    Button(action: {
                        Defaults.setFound(fish.item.name, isFound: !fish.item.found)
                        fish.item.found.toggle()
                        fish.changed.send(fish.item)
                    }, label: {
                        Text("Mark as Found")
                    })
                }
            }
            .onAppear() {
                if self.fish.count > 0 {
                    return
                }
                self.presenter.changeData()
            }.onReceive(presenter.changed) { (output) in
                self.fish = output
            }.onReceive(hideFound.changed) { (output) in
                self.presenter.filter(self.fish, hideFound: output)
            }.navigationBarTitle("Fish")
            .navigationBarItems(
                leading:
                Toggle(isOn: $hideFound.hideFound, label: { Text("Hide Found") }), trailing:
            Button(action: {
                self.showingSheet = true
            }, label: {
                Text("Sort")
            })
                #if os(iOS)
                .actionSheet(isPresented: $showingSheet) {
                ActionSheet(title: Text("Sort Fish"), buttons: [
                    .default(Text("Price"), action: {
                        self.presenter.sort(self.fish, sortOption: .price)
                }), .default(Text("A-Z"), action: {
                    self.presenter.sort(self.fish, sortOption: .aToZ)
                }), .cancel()])
                }
            #endif
            )
        }.phoneOnlyStackNavigationView()
    }
}

extension View {
    func phoneOnlyStackNavigationView() -> some View {
//        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
//        } else {
//            return AnyView(self)
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
