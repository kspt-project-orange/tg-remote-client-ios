//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

private let domain = "tg-remote-client::ApiClient"

struct Errors {
    static let badRequest: Error = { NSError(domain: domain, code: ErrorCodes.badRequest.rawValue) }()
    static let badResponse: Error = { NSError(domain: domain, code: ErrorCodes.badResponse.rawValue) }()
}

private enum ErrorCodes: Int {
    case badRequest
    case badResponse
}
