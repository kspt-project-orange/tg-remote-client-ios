//
// Created by anton.lamtev on 06/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: self)
    }
}
