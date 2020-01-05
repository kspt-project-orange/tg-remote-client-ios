//
// Created by anton.lamtev on 05/01/2020.
// Copyright (c) 2020 KSPT Orange. All rights reserved.
//

import Foundation

struct SignInRequest: RequestBody {
    let token: String
    let code: String
}
