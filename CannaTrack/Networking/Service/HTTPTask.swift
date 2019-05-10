//
//  HTTPTask.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

public typealias HTTPHeaders = [String:String]

public enum HTTPTask {
	case request

	case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)

	case requestParametersAndHeaders(bodyParameters: Parameters?, urlParameters: Parameters?, additionHeaders: HTTPHeaders?)

	// case download, upload,... etc
	

}
