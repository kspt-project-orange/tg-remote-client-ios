//
//  TabViewController.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 05/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

//final class TabViewController: UITabBarController {
final class TabViewController: UIViewController {
    private lazy var logoutBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("LOGOUT".localized(), for: .normal)
        b.setTitleColorForAllStates(Colors.text)
        b.addTarget(self, action: #selector(logoutBtnClicked), for: .touchUpInside)

        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.background

        view.addSubview(logoutBtn)

        logoutBtn.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }

    @objc
    private func logoutBtnClicked() {
        guard let window = UIApplication.shared.keyWindow else { return }
        window.rootViewController = AuthViewController(clean: true)
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
    }
}
