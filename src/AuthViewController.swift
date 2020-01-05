//
//  AuthViewController.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 04/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import UIKit
import GoogleSignIn
import Resolver

final class AuthViewController: UIViewController {
    @Injected
    private var client: ApiClient

    override func viewDidLoad() {
        super.viewDidLoad()
        client.requestCode(body: RequestCodeRequest(phone: "+79811585160")) { res in
            switch res {
            case .success(let response):
                print(response.status)
                print(response.token)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
