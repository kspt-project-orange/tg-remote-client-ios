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
import Combine
import Then

final class ApiClient {
    private enum Methods {
        static let post = "POST"
    }

    private enum Headers {
        static let contentType = "Content-Type"
    }

    private enum MediaTypes {
        static let applicationJson = "application/json"
    }

    private enum Endpoints {
        static let local = "http://192.168.86.41:8080"
        static let heroku = ""
    }

    private enum Paths {
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
    @Injected
    private var preferences: PreferenceService

    private var endpoint: String {
        preferences.serverUrl ?? Endpoints.local
    }

    func requestCode(body: RequestCodeRequest) -> AnyPublisher<RequestCodeResponse, Error> {
        postMethod(withPath: Paths.requestCode, body: body)
    }

    func signIn(body: SignInRequest) -> AnyPublisher<SignInResponse, Error> {
        postMethod(withPath: Paths.signIn, body: body)
    }

    func pass2Fa(body: Pass2FaRequest) -> AnyPublisher<Pass2FaResponse, Error> {
        postMethod(withPath: Paths.pass2Fa, body: body)
    }

    func attachDrive(body: AttachDriveRequest) -> AnyPublisher<AttachDriveResponse, Error> {
        postMethod(withPath: Paths.attachDrive, body: body)
    }

    private func postMethod<Req: RequestBody, Resp: ResponseBody>(withPath path: String, body: Req) -> AnyPublisher<Resp, Error> {
        Future<URL, Error> { [endpoint] promise in
                guard let url = URL(string: endpoint + path) else {
                    return promise(.failure(Errors.badRequest))
                }

                return promise(.success(url))
            }
            .zip(Just(body)
                    .encode(encoder: encoder)
                    .catch { _ in Fail<Data, Error>(error: Errors.badRequest) })
            .map { url, data in
                URLRequest(url: url).with {
                    $0.httpMethod = Methods.post
                    $0.httpBody = data
                    $0.setValue(MediaTypes.applicationJson, forHTTPHeaderField: Headers.contentType)
                }
            }
            .flatMap { [session, decoder] request in
                session.dataTaskPublisher(for: request)
                        .map { $0.data }
                        .decode(type: Resp.self, decoder: decoder)
                        .catch { _ in Fail<Resp, Error>(error: Errors.badResponse) }
            }
            .eraseToAnyPublisher()
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
