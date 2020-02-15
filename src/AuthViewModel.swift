//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation
import Resolver
import GoogleSignIn
import Combine

protocol AuthViewModelDelegate: AnyObject {
    func authViewModel(_ viewModel: AuthViewModel, didAuthorizeSuccessfully successfully: Bool)
}

final class AuthViewModel: NSObject {
    private enum Credentials {
        static let googleSignInClientId = "565708888148-a37kf3ulpe79hsbc5rrkur4p0nh8tg7r.apps.googleusercontent.com"
        static let googleSignInServerClientId = "565708888148-1j57f0ofnk1b0a2gsk23el5v2ec4cuo0.apps.googleusercontent.com"
    }

    private enum GoogleDriveScopes {
        static let file = "https://www.googleapis.com/auth/drive.file"
        static let metadata = "https://www.googleapis.com/auth/drive.metadata"
        static let all = [file, metadata]
    }

    @Injected
    private var client: ApiClient
    @Injected
    private(set) var preferences: PreferenceService
    private(set) var state: State!

    weak var delegate: AuthViewModelDelegate?

    static let instance = { AuthViewModel() }()

    private override init() {
        super.init()
        state = preferences.hasTelegramAuthorization ? .waitingForGoogleSignIn : .waitingForPhone

        GIDSignIn.sharedInstance().clientID = Credentials.googleSignInClientId
        GIDSignIn.sharedInstance().serverClientID = Credentials.googleSignInServerClientId
        GIDSignIn.sharedInstance().scopes.append(contentsOf: GoogleDriveScopes.all)
        GIDSignIn.sharedInstance().delegate = self
    }

    func sendPhoneNumber(_ phone: String) -> AnyPublisher<Bool, Never> {
        client
            .requestCode(body: RequestCodeRequest(phone: phone))
            .map { [weak self] response in
                guard let self = self, response.status == .ok, let token = response.token else { return false }

                self.state = .waitingForCode
                self.preferences.token = token
                return true
            }
            .catch { err -> Just<Bool> in
                print(err)
                return Just(false)
            }
            .eraseToAnyPublisher()
    }

    func sendCode(_ code: String) -> AnyPublisher<Bool, Never> {
        client
            .signIn(body: SignInRequest(token: preferences.token!, code: code))
            .map { [weak self] response in
                guard let self = self, response.status != .error else { return false }

                if response.status == .ok {
                    self.state = .waitingForGoogleSignIn
                    self.preferences.hasTelegramAuthorization = true
                } else if response.status == .tfaRequired {
                    self.state = .waitingForPassword
                }

                return true
            }
            .catch { err -> Just<Bool> in
                print(err)
                return Just(false)
            }
            .eraseToAnyPublisher()
    }

    func sendPassword(_ password: String) -> AnyPublisher<Bool, Never> {
        client
            .pass2Fa(body: Pass2FaRequest(token: preferences.token!, password: password))
            .map { [weak self] response in
                guard let self = self, response.status == .ok else { return false }

                self.state = .waitingForGoogleSignIn
                self.preferences.hasTelegramAuthorization = true
                return true
            }
            .catch { err -> Just<Bool> in
                print(err)
                return Just(false)
            }
            .eraseToAnyPublisher()
    }

    func reset(completion: () -> Void) {
        preferences.hasTelegramAuthorization = false
        preferences.hasGoogleDriveAuthorization = false
        preferences.token = nil
        preferences.googleIdToken = nil
        preferences.googleServerAuthCode = nil

        state = .waitingForPhone

        completion()
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
        guard error == nil else {
            print(error!)
            self.delegate?.authViewModel(self, didAuthorizeSuccessfully: false)
            return
        }

        var success = false
        user.authentication.getTokensWithHandler { auth, err in
            guard error == nil,
                  let auth = auth,
                  let serverAuthCode = user.serverAuthCode else {
                print(error!)
                return
            }

            self.preferences.googleIdToken = auth.idToken
            self.preferences.googleServerAuthCode = serverAuthCode
            success = true
        }

        guard success else {
            self.delegate?.authViewModel(self, didAuthorizeSuccessfully: false)
            return
        }

        _ = client
                .attachDrive(body: AttachDriveRequest(
                    token: preferences.token!,
                    driveIdToken: preferences.googleIdToken!,
                    driveServerAuthCode: preferences.googleServerAuthCode!
                ))
                .map { [weak self] response in
                    guard let self = self, response.status == .ok else { return false }

                    self.state = .authorized
                    self.preferences.hasGoogleDriveAuthorization = true
                    return true
                }
                .catch { err -> Just<Bool> in
                    print(err)
                    return Just(false)
                }
                .subscribe(on: RunLoop.main)
                .sink { [weak self] success in
                    self?.delegate?.authViewModel(self!, didAuthorizeSuccessfully: success)
                }
    }
}
