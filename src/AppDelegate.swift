//
//  AppDelegate.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 04/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import UIKit
import Resolver
import GoogleSignIn

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    @Injected
    private var preferences: PreferenceService
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupWindow()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        GIDSignIn.sharedInstance().handle(url)
    }

    private func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        if preferences.hasAuthorization {
            window?.rootViewController = TabViewController()
        } else {
            window?.rootViewController = AuthViewController()
        }
        window?.makeKeyAndVisible()
    }
}
