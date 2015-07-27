//
//  Model.swift
//  tutu-parsing
//
//  Created by Valerii Solodovnyk on 22.07.15.
//  Copyright (c) 2015 Valerii Solodovnyk. All rights reserved.
//

import Foundation
import RealmSwift

//  v1
class RouteMap: Object {
    dynamic var points = ""
    dynamic var name = ""
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    
}

class Station: Object {
    dynamic var code = 0
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    dynamic var name_uk = ""
    dynamic var name_en = ""
    dynamic var name_ru = ""
    dynamic var relatedStations = List<Station>()
    
    var name: String? {
        switch currentLanguage {
        case "en": return name_en
        case "ru": return name_ru
        case "uk": return name_uk
        default: return nil
        }
    }

    override static func primaryKey() -> String? {
        return "code"
    }

    func addRelatedStation (station: Station) -> Bool {
        for rel in self.relatedStations {
            if rel.code == station.code {
                return false
            }
        }
        self.relatedStations.append(station)
        return true
    }
}

class Train: Object {
    dynamic var arrival = ""
    dynamic var daysOnTheRoad = 0
    dynamic var departure = ""
    dynamic var name = ""
    dynamic var number = ""
    dynamic var periodicity = ""
    dynamic var stationArrival: Station?
    dynamic var stationDeparture: Station?
    dynamic var trainId = ""
    dynamic var travelTime = ""
    dynamic var route = List<Route>()
    
    dynamic var arrivalToShow = ""
    dynamic var departureToShow = ""
    dynamic var numberInRouteForStationFrom = 0
    dynamic var numberInRouteForStationTo = 0
    dynamic var daysOnTheRoadTo = 0
    dynamic var daysOnTheRoadFrom = 0
    
    override static func ignoredProperties() -> [String] {
        return ["arrivalToShow",
            "departureToShow",
            "numberInRouteForStationFrom",
            "numberInRouteForStationTo",
            "daysOnTheRoadTo",
            "daysOnTheRoadFrom"]
    }
    override class func primaryKey() -> String {
        return "trainId"
    }
}


class Route: Object {
    dynamic var arrival  = ""
    dynamic var departure = ""
    dynamic var numberInRoute = 0
    dynamic var daysOnTheRoad = 0
    dynamic var station: Station?
    
    var train: [Train] {
        return linkingObjects(Train.self, forProperty: "route")
    }
    dynamic var stojanka = ""
    dynamic var kilometraz = ""
    dynamic var time = ""
}

class RouteTUTU: Object {
    dynamic var code = ""
    dynamic var name = ""
    dynamic var prib = ""
    dynamic var stojanka = ""
    dynamic var otpr = ""
    dynamic var kilometraz = ""
    dynamic var v_puti = ""
    var trains: [TrainNP] {
        return linkingObjects(TrainNP.self, forProperty: "routesTUTU")
    }
}




class TrainNP: Object {
    dynamic var np = ""
    dynamic var schedule = ""
    dynamic var route = ""
    dynamic var routeMap = ""
    dynamic var name = ""
    let routesTUTU = List<RouteTUTU>()
    let routesMap = List<RouteMap>()
    
    
    override static func primaryKey() -> String? {
        return "np"
    }
}
