//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation
import Resolver
import GoogleSignIn
import os

protocol AuthViewModelDelegate: AnyObject {
    func authViewModelDidBecomeAuthorized(_ viewModel: AuthViewModel)
}

final class AuthViewModel: NSObject {
    private struct Credentials {
        static let googleSignInClientId = "565708888148-a37kf3ulpe79hsbc5rrkur4p0nh8tg7r.apps.googleusercontent.com"
        static let googleSignInServerClientId = "565708888148-1j57f0ofnk1b0a2gsk23el5v2ec4cuo0.apps.googleusercontent.com"
    }

    private struct GoogleDriveScopes {
        static let file = "https://www.googleapis.com/auth/drive.file"
        static let metadata = "https://www.googleapis.com/auth/drive.metadata"
        static let all = [file, metadata]
    }

    @Injected
    private var client: ApiClient
    @Injected
    private var preferences: PreferenceService
    private(set) var state: State!

    weak var delegate: AuthViewModelDelegate?

    static var instance = { AuthViewModel() }()

    private override init() {
        super.init()
        state = preferences.hasTelegramAuthorization ? .waitingForGoogleSignIn : .waitingForPhone

        GIDSignIn.sharedInstance().clientID = Credentials.googleSignInClientId
        GIDSignIn.sharedInstance().serverClientID = Credentials.googleSignInServerClientId
        GIDSignIn.sharedInstance().scopes.append(contentsOf: GoogleDriveScopes.all)
        GIDSignIn.sharedInstance().delegate = self
    }

    func sendPhoneNumber(_ phone: String, completion: @escaping (Bool) -> Void) {
        client.requestCode(body: RequestCodeRequest(phone: phone)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                if response.status == .ok, let token = response.token {
                    self.state = .waitingForCode
                    self.preferences.token = token
                    completion(true)
                    return
                }
                completion(false)
            case .failure(let error):
                print("\(error)")
                completion(false)
            }
        }
    }

    func sendCode(_ code: String, completion: @escaping (Bool) -> Void) {
        client.signIn(body: SignInRequest(token: preferences.token, code: code)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                if response.status == .error {
                    completion(false)
                    return
                }

                if response.status == .ok {
                    self.state = .waitingForGoogleSignIn
                    self.preferences.hasTelegramAuthorization = true
                } else if response.status == .tfaRequired {
                    self.state = .waitingForPassword
                }
                completion(true)
            case .failure(let error):
                print("\(error)")
                completion(false)
            }
        }
    }

    func sendPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        client.pass2Fa(body: Pass2FaRequest(token: preferences.token, password: password)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                if response.status == .ok {
                    self.state = .waitingForGoogleSignIn
                    self.preferences.hasTelegramAuthorization = true
                    completion(true)
                    return
                }
                completion(false)
            case .failure(let error):
                print("\(error)")
                completion(false)
            }
        }
    }

    enum State {
        case waitingForPhone
        case waitingForCode
        case waitingForPassword
        case waitingForGoogleSignIn
        case authorized
    }
}

extension AuthViewModel: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else { return }

        user.authentication.getTokensWithHandler { auth, err in
            guard error == nil, let auth = auth else { return }

            self.preferences.googleSignInToken = auth.accessToken
        }

        client.attachDrive(body: AttachDriveRequest(token: preferences.token, driveToken: preferences.googleSignInToken)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                switch response.status {
                case .ok:
                    self.state = .authorized
                    self.preferences.hasGoogleDriveAuthorization = true
                    self.delegate?.authViewModelDidBecomeAuthorized(self)
                default:
                    break
                }
            case .failure(let error):
                print("\(error)")
                break
            }
        }
    }
}
