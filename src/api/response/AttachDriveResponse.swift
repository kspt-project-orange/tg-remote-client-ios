//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

struct AttachDriveResponse: ResponseBody {
    let status: Status

    enum Status: String, Decodable {
        case ok = "OK"
        case wrongIdToken = "WRONG_ID_TOKEN"
        case wrongServerAuthCode = "WRONG_SERVER_AUTH_CODE"
        case notEnoughRights = "NOT_ENOUGH_RIGHTS"
        case error = "ERROR"
    }
}
