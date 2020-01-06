//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

struct AttachDriveRequest: RequestBody {
    let token: String
    let driveToken: String
}
