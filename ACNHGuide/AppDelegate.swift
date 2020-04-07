//
//  AppDelegate.swift
//  ACNHGuide
//
//  Created by Christopher Truman on 3/22/20.
//  Copyright © 2020 truman. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(swapTabs(keyCommand:)), discoverabilityTitle: "Open Bug Tab"),
            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(swapTabs(keyCommand:)), discoverabilityTitle: "Open Fish Tab")
        ]
    }

    @objc func swapTabs(keyCommand: UIKeyCommand) {
        switch keyCommand.input!.contains("f") {
        case true:
            NotificationCenter.default.post(name: .fish, object: nil)
        case false:
            NotificationCenter.default.post(name: .bug, object: nil)
        }
    }

}

extension Notification.Name {
    static let fish = Notification.Name("Switch.Fish")
    static let bug = Notification.Name("Switch.Bug")
}
