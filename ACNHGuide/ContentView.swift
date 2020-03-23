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

struct ItemView: View {

    var item: Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.name)
                Text("\(item.price)")
            }
            Spacer()
            if item.found {
                Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20.0))
                .foregroundColor(.green)
            }
        }
    }
}

struct BugList: View {
    @State var bugs = [Item]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false

    var presenter = Presenter(filename: "bugs")

    var body: some View {
        NavigationView {
            List(bugs) { bug in
                ItemView(item: bug)
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
                }
            )
        }
    }
}

struct FishList: View {
    @State var fish = [Item]()
    @ObservedObject private var hideFound = ToggleModel()
    @State private var showingSheet = false

    var presenter = Presenter(filename: "fish")

    var body: some View {
        NavigationView {
            List(fish) { fish in
                ItemView(item: fish)
                .contextMenu {
                    Button(action: {
                        Defaults.setFound(fish.name, isFound: !fish.found)
                        self.presenter.changeData()
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
            }).actionSheet(isPresented: $showingSheet) {
                ActionSheet(title: Text("Sort Fish"), buttons: [
                    .default(Text("Price"), action: {
                        self.presenter.sort(self.fish, sortOption: .price)
                }), .default(Text("A-Z"), action: {
                    self.presenter.sort(self.fish, sortOption: .aToZ)
                }), .cancel()])
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
