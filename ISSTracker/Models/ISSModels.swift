//
//  ISSModels.swift
//  ISSTracker
//
//  Created by Seif Kobrosly on 9/14/22.
//

import Foundation
import CoreLocation

// MARK: - ISSNow
struct ISSNow: Codable {
    let timestamp: Int
    let message: String
    let issPosition: ISSPosition

    enum CodingKeys: String, CodingKey {
        case timestamp, message
        case issPosition = "iss_position"
    }
}

// MARK: - ISSPosition
struct ISSPosition: Codable {
    let latitude, longitude: CLLocationDegrees

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let lng = try CLLocationDegrees(container.decode(String.self, forKey: .longitude)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.longitude], debugDescription: "Expecting string representation of double"))
        }
        longitude = lng
        guard let lat = try CLLocationDegrees(container.decode(String.self, forKey: .latitude)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.latitude], debugDescription: "Expecting string representation of double"))
        }
        latitude = lat
    }

    func locationCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude,
                                      longitude: self.longitude)
    }
}
