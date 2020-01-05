//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

struct RequestCodeResponse: ResponseBody {
    let status: Status
    let token: String?

    enum Status: String, Decodable {
        case ok = "OK"
        case error = "ERROR"
    }
}
