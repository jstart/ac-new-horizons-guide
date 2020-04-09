//
//  SearchView.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 4/6/20.
//  Copyright © 2020 truman. All rights reserved.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchView: UIViewRepresentable {

    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate, UITextFieldDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            if text.count == 0 {
                searchBar.resignFirstResponder()
            }
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            textField.text = ""
            return false
        }

        @objc public func resignKeyboard() {
            UIApplication.shared.endEditing()
        }
    }

    func makeCoordinator() -> SearchView.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchView>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.returnKeyType = .done
//        let toolbar = UIToolbar(frame: .zero)
//        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: nil)]
//        searchBar.searchTextField.inputAccessoryView = toolbar
        searchBar.delegate = context.coordinator
        searchBar.searchTextField.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchView>) {
        uiView.text = text
    }
}
