//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

struct Pass2FaResponse: ResponseBody {
    let status: Status

    enum Status: String, Decodable {
        case ok = "OK"
        case error = "ERROR"
    }
}
