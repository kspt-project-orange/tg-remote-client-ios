//
//  ApiClient.swift
//  tg-remote-client
//
//  Created by anton.lamtev on 05/01/2020.
//  Copyright © 2020 KSPT Orange. All rights reserved.
//

import Foundation
import Resolver
import ZippyJSON

final class ApiClient {
    private struct Methods {
        static let post = "POST"
    }

    private struct Headers {
        static let contentType = "Content-Type"
    }

    private struct MediaTypes {
        static let applicationJson = "application/json"
    }

    private struct Endpoints {
        static let local = "http://192.168.86.41:8080"
        static let heroku = ""
    }

    private struct Paths {
        static let requestCode = "/v0/auth/requestCode"
        static let signIn = "/v0/auth/signIn"
        static let pass2Fa = "/v0/auth/pass2FA"
        static let attachDrive = "/v0/auth/attachDrive"
    }

    @Injected
    private var encoder: JSONEncoder
    @Injected
    private var decoder: ZippyJSONDecoder
    @Injected
    private var session: URLSession

    func requestCode(body: RequestCodeRequest, completion: @escaping (Result<RequestCodeResponse, Error>) -> Void) {
        postMethod(withPath: Paths.requestCode, body: body, completion: completion)
    }

    func signIn(body: SignInRequest, completion: @escaping (Result<SignInResponse, Error>) -> Void) {
        postMethod(withPath: Paths.signIn, body: body, completion: completion)
    }

    func pass2Fa(body: Pass2FaRequest, completion: @escaping (Result<Pass2FaResponse, Error>) -> Void) {
        postMethod(withPath: Paths.pass2Fa, body: body, completion: completion)
    }

    func attachDrive(body: AttachDriveRequest, completion: @escaping (Result<AttachDriveResponse, Error>) -> Void) {
        postMethod(withPath: Paths.attachDrive, body: body, completion: completion)
    }

    private func postMethod<Req: RequestBody, Resp: ResponseBody>(withPath path: String, body: Req, completion: @escaping (Result<Resp, Error>) -> Void) {
        guard let url = URL(string: Endpoints.local + path),
              let data = try? encoder.encode(body) else {
            completion(.failure(Errors.badRequest))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = Methods.post
        request.httpBody = data
        request.setValue(MediaTypes.applicationJson, forHTTPHeaderField: Headers.contentType)

        session.dataTask(with: request) { [unowned self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let code = (response as? HTTPURLResponse)?.statusCode, code.isAccepted,
                  let data = data,
                  let responseBody = try? self.decoder.decode(Resp.self, from: data) else {
                completion(.failure(Errors.badResponse))
                return
            }

            completion(.success(responseBody))
        }.resume()
    }
}

private extension Int {
    var isOk: Bool {
        self == 200
    }

    var isAccepted: Bool {
        self == 202
    }
}
