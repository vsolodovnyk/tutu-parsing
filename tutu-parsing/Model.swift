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

}



class Route: Object {
    dynamic var code = ""
    dynamic var name = ""
    dynamic var prib = ""
    dynamic var stojanka = ""
    dynamic var otpr = ""
    dynamic var kilometraz = ""
    dynamic var v_puti = ""
    var trains: [TrainNP] {
        return linkingObjects(TrainNP.self, forProperty: "routes")
    }
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
    let routes = List<Route>()
    let routesTUTU = List<RouteTUTU>()
    let routesMap = List<RouteMap>()
    
    
    override static func primaryKey() -> String? {
        return "np"
    }
}
//  v0
//class RouteMap: Object {
//    dynamic var points = ""
//}
//
//class Route: Object {
//    dynamic var code = ""
//    dynamic var name = ""
//    dynamic var prib = ""
//    dynamic var stojanka = ""
//    dynamic var otpr = ""
//    dynamic var kilometraz = ""
//    dynamic var v_puti = ""
//    
//}
//
//class TrainNP: Object {
//    dynamic var np = ""
//    dynamic var schedule = ""
//    dynamic var route = ""
//    dynamic var routeMap = ""
//    dynamic var name = ""
//    let routes = List<Route>()
//    let routesMap = List<RouteMap>()
//    
//        
//    override static func primaryKey() -> String? {
//        return "np"
//    }
//}