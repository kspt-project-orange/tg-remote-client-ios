//
//  ApiClient+Injection.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 05/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import Foundation
import Resolver
import ZippyJSON

extension Resolver {
    public static func registerApiDependencies() {
        register { JSONEncoder() }
        register { ZippyJSONDecoder() }

        register { URLSession(configuration: .default) }
    }
}
