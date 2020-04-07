//
//  ContentView.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 3/22/20.
//  Copyright © 2020 truman. All rights reserved.
//

import SwiftUI
import Combine

class TabModel {
    @State var selection: Int

    init() {
        self.selection = 0

    }
}

struct ContentView: View {
    @State private var selection = 0
    private var notificationFish = NotificationCenter.default.publisher(for: .fish).compactMap { $0 }
    private var notificationBug = NotificationCenter.default.publisher(for: .bug).compactMap { $0 }

    var body: some View {
        TabView(selection: $selection) {
            ItemList(presenter: Presenter(filename: "bugs"))
            .tabItem {
                VStack {
                    Image(systemName: "ant")
                    Text("Bugs")
                }
            }
            .tag(0)
            ItemList(presenter: Presenter(filename: "fish"))
            .tabItem {
                VStack {
                    Image(systemName: "tortoise")
                    Text("Fish")
                }
            }
            .tag(1)
        }.onReceive(notificationBug, perform: { _ in
            self.selection = 0
            UIApplication.shared.endEditing()
        })
        .onReceive(notificationFish, perform: { _ in
            self.selection = 1
            UIApplication.shared.endEditing()
        })
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

class PlatformModel {
    @State var isTablet: Bool

    init() {
        self.isTablet = UIDevice.current.userInterfaceIdiom == .pad
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
                    Text(item.name).font(.system(.title, design: .rounded)).bold()
                    Text("\(item.price) Bells")
                    Text("Available: \(item.time), \(item.seasonality)")
                    Text("\(item.location)")
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

struct ItemList: View {
    @State var itemModels = [ItemViewModel]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false
    @State private var showingAlert = false
    @State private var platformModel = PlatformModel()
    @State private var searchTerm: String = ""

    var presenter: Presenter

    var body: some View {
        NavigationView {
            VStack {
                SearchView(text: self.$searchTerm)
                List(itemModels.filter {
                    self.searchTerm.isEmpty ? true :    $0.item.name.localizedStandardContains(self.searchTerm) }) { itemModel in
                    ItemView(viewModel: itemModel, item: itemModel.item)
                    .onTapGesture {
                        Defaults.setFound(itemModel.item.name, isFound: !itemModel.item.found)
                        itemModel.item.found.toggle()
                        itemModel.changed.send(itemModel.item)
                        UIApplication.shared.endEditing()
                    }
//                    .contextMenu {
//                        Button(action: {
//                            Defaults.setFound(itemModel.item.name, isFound: !itemModel.item.found)
//                            itemModel.item.found.toggle()
//                            itemModel.changed.send(itemModel.item)
//                        }, label: {
//                            Text("Mark as Found")
//                        })
//                    }
                }
                .onAppear() {
                    if self.itemModels.count > 0 {
                        return
                    }
                    self.presenter.changeData()
                }.onReceive(presenter.changed) { (output) in
                    self.itemModels = output
                    UIApplication.shared.endEditing()
                }.onReceive(hideFound.changed) { (output) in
                    UIApplication.shared.endEditing()
                    self.presenter.filter(self.itemModels, hideFound: output)
                }.navigationBarTitle(presenter.filename.localizedCapitalized)
                .navigationBarItems(leading:
                    Toggle(isOn: $hideFound.hideFound, label: { Text("Hide Found") }), trailing:
                Button(action: {
                    if self.platformModel.isTablet {
                        self.showingAlert.toggle()
                    } else {
                        self.showingSheet.toggle()
                    }
                }, label: {
                    Text("Sort")
                }).actionSheet(isPresented: $showingSheet) {
                    ActionSheet(title: Text("Sort \(presenter.filename.localizedCapitalized)"), buttons: [
                        .default(Text("Price"), action: {
                            self.presenter.sort(self.itemModels, sortOption: .price)
                    }), .default(Text("A-Z"), action: {
                        self.presenter.sort(self.itemModels, sortOption: .aToZ)
                    }), .cancel()])
                    }.scaledToFill()
                    .popover(isPresented: $showingAlert, attachmentAnchor: .point(.bottomTrailing), arrowEdge: .top, content: {
                        VStack {
                            Spacer()
                            Button(action: {
                                self.showingAlert.toggle()
                                self.presenter.sort(self.itemModels, sortOption: .price)
                                }, label: { Text("  Sort by Price  ") })
                            Spacer()
                            Button(action: {
                                self.showingAlert.toggle()
                                self.presenter.sort(self.itemModels, sortOption: .aToZ)
                                }, label: { Text("  Sort by A-Z  ") })
                            Spacer()
                        }
                    })
                )
            }
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
