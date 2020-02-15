//
//  AuthViewController.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 04/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import UIKit
import Resolver
import GoogleSignIn
import SnapKit
import SwifterSwift
import Combine
import Then

final class AuthViewController: UIViewController {
    @Injected
    private var viewModel: AuthViewModel

    private lazy var text = UILabel().then {
        $0.backgroundColor = Colors.background
        $0.textAlignment = .center
        $0.textColor = Colors.text
        $0.numberOfLines = 2
    }

    private lazy var input = UITextField().then {
        $0.isHidden = !([.waitingForPhone, .waitingForCode, .waitingForPassword] as [AuthViewModel.State]).contains(viewModel.state)
        $0.borderStyle = .roundedRect
        $0.borderColor = Colors.border
        $0.delegate = self
    }

    private lazy var button = UIButton().then {
        $0.isHidden = !([.waitingForPhone, .waitingForCode, .waitingForPassword] as [AuthViewModel.State]).contains(viewModel.state)
        $0.cornerRadius = 8.0
        $0.setTitle("AUTHORIZATION_BUTTON_NEXT".localized(), for: .normal)
        $0.setTitleColor(Colors.text, for: .normal)
        $0.setTitleColor(Colors.text.withAlphaComponent(0.5), for: .highlighted)
        $0.backgroundColor = Colors.background
        $0.borderColor = Colors.text
        $0.borderWidth = 1.0
        $0.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
    }

    private lazy var googleSignInButton = GIDSignInButton().then {
        $0.isHidden = viewModel.state != .waitingForGoogleSignIn
        $0.style = .wide
    }

    private lazy var semitransparentView = UIView().then {
        $0.backgroundColor = Colors.background.withAlphaComponent(0.5)
        $0.isHidden = true
        $0.isUserInteractionEnabled = false
    }

    private lazy var prefBtn = UIButton(type: .system).then {
        $0.setTitle("PREF_BUTTON_TITLE".localized(), for: .normal)
        $0.backgroundColor = Colors.background
        $0.titleLabel?.textAlignment = .center
        $0.setTitleColorForAllStates(Colors.text)
        $0.addTarget(self, action: #selector(prefBtnClicked), for: .touchUpInside)
    }

    init(clean: Bool = false) {
        super.init(nibName: nil, bundle: nil)

        if clean {
            viewModel.reset {
                self.updateUI()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.background

        viewModel.delegate = self
        GIDSignIn.sharedInstance().presentingViewController = self

        updateUI()

        [text, input, button, googleSignInButton, semitransparentView, prefBtn].forEach(view.addSubview)
        view.bringSubviewToFront(semitransparentView)

        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        semitransparentView.frame = view.bounds
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        text.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view).offset(128.0)
        }

        input.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(text.snp.bottom).offset(32.0)
            make.left.greaterThanOrEqualTo(view).offset(32.0)
            make.right.lessThanOrEqualTo(view).offset(-32.0)
        }

        button.snp.makeConstraints { make in
            make.top.equalTo(input.snp.bottom).offset(32.0)
            make.height.equalTo(48.0)
            make.width.equalTo(128.0)
            make.centerX.equalTo(view)
        }

        googleSignInButton.snp.makeConstraints { make in
            make.top.equalTo(text.snp.bottom).offset(32.0)
            make.centerX.equalTo(view)
        }

        prefBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-64.0)
            make.centerX.equalTo(view)
            make.size.equalTo(prefBtn)
        }
    }

    private func updateUI() {
        input.text = ""
        switch viewModel.state {
        case .waitingForPhone:
            text.text = "AUTHORIZATION_ENTER_TELEGRAM_PHONE_LABEL".localized()
            input.placeholder = "AUTHORIZATION_ENTER_TELEGRAM_PHONE_INPUT_PLACEHOLDER".localized()
            input.isSecureTextEntry = false
            input.keyboardType = .phonePad
            input.isHidden = false
            button.isHidden = false
            googleSignInButton.isHidden = true
        case .waitingForCode:
            text.text = "AUTHORIZATION_ENTER_TELEGRAM_CODE_LABEL".localized()
            input.placeholder = "AUTHORIZATION_ENTER_TELEGRAM_CODE_INPUT_PLACEHOLDER".localized()
            input.isSecureTextEntry = false
            input.keyboardType = .numberPad
            input.isHidden = false
            button.isHidden = false
            googleSignInButton.isHidden = true
        case .waitingForPassword:
            text.text = "AUTHORIZATION_ENTER_TELEGRAM_PASSWORD_LABEL".localized()
            input.placeholder = "AUTHORIZATION_ENTER_TELEGRAM_PASSWORD_INPUT_PLACEHOLDER".localized()
            input.isSecureTextEntry = true
            input.keyboardType = .default
            input.isHidden = false
            button.isHidden = false
            googleSignInButton.isHidden = true
        case .waitingForGoogleSignIn:
            text.text = "AUTHORIZATION_ENTER_GOOGLE_DRIVE_LABEL".localized()
            input.isHidden = true
            button.isHidden = true
            googleSignInButton.isHidden = false
        case .authorized:
            dismiss(animated: true)
            guard let window = UIApplication.shared.keyWindow else { return }
            window.rootViewController = TabViewController()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
        default:
            fatalError()
        }
    }

    @objc
    private func buttonClicked() {
        semitransparentView.isHidden = false
        view.isUserInteractionEnabled = false

        input.resignFirstResponder()
        switch viewModel.state {
        case .waitingForPhone:
            _ = viewModel
                    .sendPhoneNumber(input.text!)
                    .subscribe(on: RunLoop.main)
                    .sink { [weak self] success in
                        self?.updateUIOnSuccess(success)
                    }
        case .waitingForCode:
            _ = viewModel
                    .sendCode(input.text!)
                    .subscribe(on: RunLoop.main)
                    .sink { [weak self] success in
                        self?.updateUIOnSuccess(success)
                    }
        case .waitingForPassword:
            _ = viewModel
                    .sendPassword(input.text!)
                    .subscribe(on: RunLoop.main)
                    .sink { [weak self] success in
                        self?.updateUIOnSuccess(success)
                    }
        default:
            break
        }
    }

    private func updateUIOnSuccess(_ success: Bool) {
        DispatchQueue.main.async {
            self.semitransparentView.isHidden = true
            self.view.isUserInteractionEnabled = true

            guard success else {
                self.showAlert(title: "AUTHORIZATION_ALERT_TITLE".localized(), message: "AUTHORIZATION_ALERT_TEXT".localized())
                return
            }

            self.updateUI()
        }
    }

    @objc
    private func prefBtnClicked() {
        let actionSheet = UIAlertController(title: "PREF_BUTTON_TITLE".localized(), message: nil, preferredStyle: .actionSheet)

        let serverUrlActionTitle = viewModel.preferences.serverUrl ?? "PREF_ACTION_SHEET_SET_SERVER_URL_ACTION_TITLE".localized()
        let serverUrlAction = UIAlertAction(title: serverUrlActionTitle, style: .default) { _ in
            let alert = UIAlertController(title: "PREF_ACTION_SHEET_SET_SERVER_URL_ACTION_TITLE".localized(), message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = serverUrlActionTitle
                textField.clearButtonMode = .whileEditing
            }
            alert.addAction(title: "PREF_ACTION_SHEET_OK_ACTION_TITLE".localized(), style: .default) { [unowned alert] _ in
                self.viewModel.preferences.serverUrl = alert.textFields![0].text
            }

            alert.addAction(title: "PREF_ACTION_SHEET_CANCEL_ACTION_TITLE".localized(), style: .cancel)
            alert.show(animated: true)
        }

        actionSheet.addAction(serverUrlAction)

        let resetAction = UIAlertAction(title: "PREF_ACTION_SHEET_RESET_ACTION_TITLE".localized(), style: .destructive) { _ in
            self.viewModel.reset {
                self.updateUI()
            }
        }
        actionSheet.addAction(resetAction)
        actionSheet.show(animated: true)

        actionSheet.addAction(title: "PREF_ACTION_SHEET_CANCEL_ACTION_TITLE".localized(), style: .cancel)
    }
}

extension AuthViewController: AuthViewModelDelegate {
    func authViewModel(_ viewModel: AuthViewModel, didAuthorizeSuccessfully successfully: Bool) {
        updateUIOnSuccess(successfully)
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }

        switch viewModel.state {
        case .waitingForPhone:
            return !string.hasLetters && textField.text!.count <= 14
        case .waitingForCode:
            return string.isDigits
        default:
            return true
        }
    }
}
