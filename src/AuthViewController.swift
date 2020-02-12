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

final class AuthViewController: UIViewController {
    @Injected
    private var viewModel: AuthViewModel

    private lazy var text: UILabel = {
        let l = UILabel()
        l.backgroundColor = Colors.background
        l.textAlignment = .center
        l.textColor = Colors.text
        l.numberOfLines = 2

        return l
    }()

    private lazy var input: UITextField = {
        let f = UITextField()
        f.isHidden = !([.waitingForPhone, .waitingForCode, .waitingForPassword] as [AuthViewModel.State]).contains(viewModel.state)
        f.borderStyle = .roundedRect
        f.borderColor = Colors.border
        f.delegate = self

        return f
    }()

    private lazy var button: UIButton = {
        let b = UIButton()
        b.isHidden = !([.waitingForPhone, .waitingForCode, .waitingForPassword] as [AuthViewModel.State]).contains(viewModel.state)
        b.cornerRadius = 8.0
        b.setTitle("AUTHORIZATION_BUTTON_NEXT".localized(), for: .normal)
        b.setTitleColor(Colors.text, for: .normal)
        b.setTitleColor(Colors.text.withAlphaComponent(0.5), for: .highlighted)
        b.backgroundColor = Colors.background
        b.borderColor = Colors.text
        b.borderWidth = 1.0
        b.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)

        return b
    }()

    private lazy var googleSignInButton: GIDSignInButton = {
        let b = GIDSignInButton()
        b.isHidden = viewModel.state != .waitingForGoogleSignIn
        b.style = .wide

        return b
    }()

    private lazy var semitransparentView: UIView = {
        let v = UIView()
        v.backgroundColor = Colors.background.withAlphaComponent(0.5)
        v.isHidden = true
        v.isUserInteractionEnabled = false

        return v
    }()

    private lazy var prefBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("PREF_BUTTON_TITLE".localized(), for: .normal)
        b.backgroundColor = Colors.background
        b.titleLabel?.textAlignment = .center
        b.setTitleColorForAllStates(Colors.text)
        b.addTarget(self, action: #selector(prefBtnClicked), for: .touchUpInside)

        return b
    }()

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
            viewModel.sendPhoneNumber(input.text!, completion: updateUIOnSuccess)
        case .waitingForCode:
            viewModel.sendCode(input.text!, completion: updateUIOnSuccess)
        case .waitingForPassword:
            viewModel.sendPassword(input.text!, completion: updateUIOnSuccess)
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
