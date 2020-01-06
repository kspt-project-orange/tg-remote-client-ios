//
// Created by anton.lamtev on 06/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import UIKit

struct Colors {
    static let background: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.systemBackground
        }
        return UIColor.white
    }()

    static let text: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.label
        }
        return UIColor.black
    }()

    static let placeholder: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.placeholderText
        }
        return UIColor.black
    }()

    static let border: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.systemFill
        }
        return UIColor.black
    }()
}
