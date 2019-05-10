//
//  ParameterEncoding.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]

public protocol ParameterEncoder {

	static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws

}
