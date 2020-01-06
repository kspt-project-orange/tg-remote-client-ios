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

private let session: URLSession = {
    let dq = DispatchQueue(label: "kspt.orange.tg-remote-client.ios.http", qos: .userInitiated, attributes: .concurrent)
    let oq = OperationQueue()
    oq.underlyingQueue = dq
    let s = URLSession(configuration: .default, delegate: nil, delegateQueue: oq)

    return s
}()

extension Resolver {
    public static func registerApiDependencies() {
        register { JSONEncoder() }
        register { ZippyJSONDecoder() }

        register { session }
    }
}
