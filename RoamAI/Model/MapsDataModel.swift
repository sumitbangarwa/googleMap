//
//  File.swift
//  RoamAI
//
//  Created by Sumit Bangarwa on 21/02/22.
//

import Foundation

struct GoogleKeys {
    static var mapApiKey = "AIzaSyDCfgFC9XocUOxvNq2WnwpTw6koj32ZDh4"
}

struct TripDataModel {
    var tripId = String()
    var startTime = String()
    var endTime = String()
    var location = [LocationDataModel]()
    
    init(id : String,startTrip: String,endTrip: String,data:[LocationDataModel]) {
        self.tripId = id
        self.startTime = startTrip
        self.endTime = endTrip
        self.location = data
    }
}


struct LocationDataModel {
    
    var latitude = String()
    var longitude = String()
    var accuracy = String()
    var timeStamp = String()
    
    init(lat : String,lon : String,accuracy : String,time:String) {
        self.latitude = lat
        self.longitude = lon
        self.accuracy = accuracy
        self.timeStamp = time
    }
}



struct USER_DEFAULTS {
    static let saveTripData = "saveTripData"
}
