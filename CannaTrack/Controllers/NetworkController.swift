//
//  NetworkManager.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

struct NetworkController {
	static let environment: NetworkEnvironment = .production
	static let strainAPIKey = "oJ5GvWc"
	private let router = Router<StrainApi>()

	enum Result<String> {
		case success
		case failure(String)
	}

	enum NetworkResponse: String {
		case success
		case authenticationError	= "You need to be authenticated first."
		case badRequest 			= "Bad request"
		case outdated				= "The url you requested is outdated."
		case failed					= "Network request failed."
		case noData					= "Response returned with no data to decode."
		case unableToDecode			= "We could not decode the response."
	}

	func handleNetworkResponse(_ response: HTTPURLResponse) -> Result<String> {
		switch response.statusCode {
		case 200...299: return .success
		case 401...500: return .failure(NetworkResponse.authenticationError.rawValue)
		case 501...599: return .failure(NetworkResponse.badRequest.rawValue)
		case 600: return .failure(NetworkResponse.outdated.rawValue)
		default: return .failure(NetworkResponse.failed.rawValue)
		}

	}

	func getNewStrains(completion: @escaping (_ strainInformation: [String: StrainInformation]?, _ error: String?) -> Void) {
		router.request(.allStrains) { (data, response, error) in
			if error != nil {
				print(error)
			}
			if let response = response as? HTTPURLResponse {
				let result = self.handleNetworkResponse(response)
				switch result {
				case .success:
					guard let responseData = data else {
						completion(nil, NetworkResponse.noData.rawValue)
						return
					}

					do {
						let apiResponse = try JSONDecoder().decode([String: StrainInformation].self, from: responseData)
						completion(apiResponse, nil)
					} catch {
						completion(nil, NetworkResponse.unableToDecode.rawValue)
					}
				case .failure(let networkFailureError):
					completion(nil, networkFailureError)
				}
			}
		}
	}

	func getEffects(for strainID: Int, completion: @escaping ((_ strainEffects: Effects?, _ error: String?) -> Void)) {
		router.request(.effects(id: strainID)) { (data, response, error) in
			if error != nil {
				print(error)
			}
			if let response = response as? HTTPURLResponse {
				let result = self.handleNetworkResponse(response)
				switch result {
				case .success:
					guard let responseData = data else {
						completion(nil, NetworkResponse.noData.rawValue)
						return
					}

					do {
						let apiResponse = try JSONDecoder().decode(Effects.self, from: responseData)
						completion(apiResponse, nil)
					} catch {
						completion(nil, NetworkResponse.unableToDecode.rawValue)
					}
				case .failure(let networkFailureError):
					completion(nil, networkFailureError)

				}
			}
		}
	}

}
