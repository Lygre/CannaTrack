//
//  StrainEndPoint.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

enum NetworkEnvironment {
	case qa
	case production
	case staging
}


public enum StrainApi {
	case allStrains
	case effects(id: Int)

}


extension StrainApi: EndPointType {


	var environmentBaseURL: String {
		let urlString = "https://strainapi.evanbusse.com/\(NetworkManager.strainAPIKey)/"
		switch NetworkManager.environment {
		case .production: return urlString
		case .qa: return urlString
		case .staging: return urlString
		}
	}

	var baseURL: URL {
		guard let url = URL(string: environmentBaseURL) else { fatalError("baseURL could not be configured")}
		return url
	}

	var path: String {
		switch self {
		case .allStrains:
			return "strains/search/all"
		case .effects(let id):
			return "strains/data/effects/\(id)"
		}
	}

	var httpMethod: HTTPMethod {
		return .get
	}

	var task: HTTPTask {
		switch self {
		case .allStrains:
//			return .requestParameters(bodyParameters: nil, urlParameters: nil)
			return .request
		default:
			return .request
		}
	}

	var headers: HTTPHeaders? {
		return nil
	}

}
