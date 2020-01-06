//
// Created by anton.lamtev on 06/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation
import SwifterSwift
import libPhoneNumber_iOS

private let phoneNumberUtil = { NBPhoneNumberUtil() }()

extension String {
    var localized: String {
        NSLocalizedString(self, comment: self)
    }

    var isPhoneNumber: Bool {
        guard let phoneNumber = try? phoneNumberUtil.parse(withPhoneCarrierRegion: self) else { return false }

        return phoneNumberUtil.isValidNumber(phoneNumber)
    }
}
