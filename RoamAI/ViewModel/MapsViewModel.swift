//
//  MapsViewModel.swift
//  RoamAI
//
//  Created by Sumit Bangarwa on 21/02/22.
//

import Foundation
import UIKit
import Alamofire

class MapsViewModel {
    
    var tripDataModel:[TripDataModel]? = []
    var locationdataModel:[LocationDataModel]? = []
    
    func updateTripData(data:TripDataModel) {
        tripDataModel?.append(data)
    }
    
    func updateLocationData(data:LocationDataModel) {
        locationdataModel?.append(data)
    }
    
    
    //Create a JSON Data and Store it
    func createJsonData() -> [String:AnyObject] {
        guard let tripData = tripDataModel else {return [:]}
        guard let locationData = locationdataModel else {return [:]}
        var topLevel :[AnyObject] = []
        var resultData:[String:AnyObject] = [:]
        var locationDict : [String:AnyObject] = [:]
        var finalLocation: [[String:AnyObject]] = [[:]]
        for jsonData in tripData {
            resultData["trip_id"] = jsonData.tripId as AnyObject
            resultData["start_time"] = jsonData.startTime as AnyObject
            resultData["end_time"] = jsonData.endTime as AnyObject
            
            for dataLocation in locationData { //appending the locations data
                locationDict["latitude"] = dataLocation.latitude as AnyObject
                locationDict["longitude"] = dataLocation.longitude as AnyObject
                locationDict["timeStamp"] = dataLocation.timeStamp as AnyObject
                locationDict["accuracy"] = dataLocation.accuracy as AnyObject
                finalLocation.append(locationDict)
            }
            
            resultData["locations"] = finalLocation as AnyObject
        }
        UserDefaults.standard.set(resultData, forKey: USER_DEFAULTS.saveTripData)
        return resultData
    }
    
    func storeJsonToDevice(){
        
        let jsonString = "\(createJsonData()) "
        
        if let jsonData = jsonString.data(using: .utf8),let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                                                            in: .userDomainMask).first {
            let pathWithFilename = documentDirectory.appendingPathComponent("RoamAI.json")
            do {
                let jsonEncoder = JSONEncoder()
                let jsonCodedData = try jsonEncoder.encode(jsonString)
                try jsonCodedData.write(to: pathWithFilename)
                print("Path:",pathWithFilename,jsonCodedData)
            } catch {
                // Handle error
                print(error.localizedDescription)
            }
        }
    }
    
    
}
