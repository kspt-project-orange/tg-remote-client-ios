//
//  PreferrenceService.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 05/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import Foundation

final class PreferenceService {
    private let userDefaults = UserDefaults.standard

    var hasTelegramAuthorization: Bool {
        get {
            value(forKey: .hasTelegramAuthorization, ofType: Bool.self)
        }
        set {
            setValue(newValue, forKey: .hasTelegramAuthorization)
        }
    }

    var hasGoogleDriveAuthorization: Bool {
        get {
            value(forKey: .hasGoogleDriveAuthorization, ofType: Bool.self)
        }
        set {
            setValue(newValue, forKey: .hasGoogleDriveAuthorization)
        }
    }

    var hasAuthorization: Bool {
        hasTelegramAuthorization && hasGoogleDriveAuthorization
    }

    private func value<T>(forKey key: Key, ofType type: T.Type) -> T {
        switch T.self {
        case is Bool.Type:
            return userDefaults.bool(forKey: key.rawValue) as! T
        default:
            fatalError()
        }
    }

    private func setValue<T>(_ value: T, forKey key: Key) {
        switch T.self {
        case is Bool.Type:
            userDefaults.set(value, forKey: key.rawValue)
        default:
            fatalError()
        }
    }

    private enum Key: String {
        case hasTelegramAuthorization
        case hasGoogleDriveAuthorization
    }
}
