//
//  Parser.swift
//  tutu-parsing
//
//  Created by Valerii Solodovnyk on 24.07.15.
//  Copyright (c) 2015 Valerii Solodovnyk. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire
import Darwin

let realm = Realm()

func populateTrainsToSchedule() {
    let trains = realm.objects(TrainNP)
    let routes = realm.objects(Route)
    
    realm.write {
        realm.delete(routes)
        for train in trains {
            let trainSchedule = Train()
            trainSchedule.trainId = train.np
            realm.add(trainSchedule, update: true)
            var routeNumber = 1
            for routePoint in train.routesTUTU {
                let code = routePoint.code.toInt()!
                if let station = realm.objectForPrimaryKey(Station.self, key: code) {
                    if station.relatedStations.count == 0 {
                        let routeSchedule = Route()
                        routeSchedule.station = station
                        routeSchedule.arrival = routePoint.prib
                        routeSchedule.departure = routePoint.otpr
                        routeSchedule.time = routePoint.v_puti
                        routeSchedule.stojanka = routePoint.stojanka
                        if let kmIndex = routePoint.kilometraz.rangeOfString(" км") {
                            routeSchedule.kilometraz = routePoint.kilometraz.substringToIndex(kmIndex.startIndex)
                        } else {
                            routeSchedule.kilometraz = routePoint.kilometraz
                        }
                        if let daysIndex = routePoint.v_puti.rangeOfString(" д") {
                            routeSchedule.daysOnTheRoad = routePoint.v_puti.substringToIndex(daysIndex.startIndex).toInt()!
                        }
                        routeSchedule.numberInRoute = routeNumber
                        routeNumber++
                        trainSchedule.route.append(routeSchedule)
                    }
                }
            }
        }
    }
    println("Populate trains from TUTU to Schedule Done!")
}

func populateMapPointName() {
    let mapPoints = realm.objects(RouteMap)
    realm.write {
        for mapPoint in mapPoints {
            var name = mapPoint.points
            if let startIndex = name.rangeOfString("<b>")?.endIndex {
                name = name.substringFromIndex(startIndex)
                if let endIndex = name.rangeOfString("<\\/b>")?.startIndex {
                    name = name.substringToIndex(endIndex)
                }
                if let bracketIndex = name.rangeOfString("(")?.startIndex {
                    name = name.substringToIndex(bracketIndex)
                }
            }
            mapPoint.name = name
            name = mapPoint.points
            
            if let lattStr = name.substring("( ", toString: ",") {
                if let latt = lattStr.toDouble() {
                    mapPoint.latitude = latt
                }
            }
            if let longStr = name.substring(", ", toString: ",") {
                if let long = longStr.toDouble() {
                    mapPoint.longitude = long
                }
            }

        }
    }
    println("RouteMap add Station names done!")
}

func printRelatedStations () {
    let sortProperties = [SortDescriptor(property: "name_ru", ascending: true), SortDescriptor(property: "code", ascending: false)]

    let stations = realm.objects(Station).sorted(sortProperties)
    var i = 0
    for (index, station) in enumerate(stations) {
        if station.relatedStations.count > 0 {
            i++
            println("\(index) Station \(station.name_ru) \(station.code) has \(station.relatedStations.count) related:")
            for relSt in station.relatedStations {
                println("     \(relSt.name_ru)  \(relSt.code)")
                if relSt.relatedStations.count > 0 {
                    println("     \(relSt.name_ru)  имеет тоже подстанции !!! в количестве \(relSt.relatedStations.count)")
                }
            }
        }
    }
    println("Станций с подстанциями \(i)")

}
func populateNamesFromTUTU () {
    let routes = realm.objects(RouteTUTU)
    
    // Write all stations from routes to Station
    realm.write {
        for route in routes {
            let station = Station()
            var name = route.name
            if let bracketIndex = name.rangeOfString("(")?.startIndex {
                name = name.substringToIndex(bracketIndex)
            }
            station.name_ru = name
            station.code = route.code.toInt()!
            station.code = route.code.toInt()!
            realm.add(station, update: true)
        }
        let stations = realm.objects(Station)
        for station in stations {
            let routemap = realm.objects(RouteMap).filter("name == '\(station.name_ru)'")
            if let routeStation = routemap.first {
                station.latitude = routeStation.latitude
                station.longitude = routeStation.longitude
            }
        }
    }
}
        
func populateStationsFromTUTU() {

    let routes = realm.objects(RouteTUTU)

    // Write all stations from routes to Station
    realm.write {
        for route in routes {
            let station = Station()
            var code = route.code
            if let index = code.rangeOfString("/poezda/station_d.php?nnst=") {
                code = code.substringFromIndex(index.endIndex)
            }
            if let index = code.rangeOfString("/station_d.php?nnst=") {
                code = code.substringFromIndex(index.endIndex)
            }
            station.code = code.toInt()!
            station.name_ru = route.name
            route.code = code
            realm.add(station, update: true)
        }
    }
}

func deleteRelatedStations () {
    let stations = realm.objects(Station)
    realm.write {
        for station in stations {
            station.relatedStations.removeAll()
        }
    }
    println("Finish delete related Station")

}

func populateRelatedStationsFromTUTU () {
    let stations = realm.objects(Station).filter("latitude == 0.0")
    let routes = realm.objects(RouteTUTU)
    realm.write {
        for station in stations {
            println("\(station.code) \(station.name_ru) ")
            for (index, route) in enumerate(routes) {
                if route.code == "\(station.code)" {
                    if index < routes.count {
                        if routes[index + 1].prib == route.prib && routes[index + 1].otpr == route.otpr {
                            if let relSt = realm.objectForPrimaryKey(Station.self, key: routes[index + 1].code.toInt()!) {
                                 station.addRelatedStation(relSt)
                            }
                           
                        }
                    }
                    
                }
            }
        }
    }
        
    
    println(stations.count)
    
    println("Finish write Related Stations")
}

func schedule () {
    
    let trains = realm.objects(TrainNP)
    //    let train = trains.last
    
    for train in trains {
        if train.name.isEmpty {
            
            let str = "http://www.tutu.ru/poezda/view_d.php?np=" + train.np
            var request = NSURLRequest(URL: NSURL(string: str)!)
            var response: NSURLResponse?
            var error: NSErrorPointer = nil
            var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error)
            var reply = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let html = reply as! String
            
            var err : NSError?
            var parser     = HTMLParser(html: html, error: &err)
            if err != nil {
                println(err)
                exit(1)
            }
            
            var bodyNode = parser.body
            let content = bodyNode?.contents
            
            if (content?.rangeOfString("captcha") != nil) {
                sleep(500)
            }
            
            realm.write {
                
                if let inputNodes = bodyNode?.findChildTags("h1") {
                    train.name = inputNodes.first!.contents.removeTabs()
                }
                
                
                if let indexRange = content!.rangeOfString("schedule: ") {
                    let str = content!.substringFromIndex(indexRange.endIndex)
                    if let indexRangeBracket = str.rangeOfString("]") {
                        let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                        train.schedule = str2.removeTabs()
                    }
                }
                if let indexRange = content!.rangeOfString("addPolyline( ") {
                    let str = content!.substringFromIndex(indexRange.endIndex)
                    if let indexRangeBracket = str.rangeOfString("]") {
                        let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                        train.routeMap = str2.removeTabs()
                    }
                }
                
                var maps = content!
                var loops = true
                while loops {
                    if let indexRange = maps.rangeOfString("addMarker") {
                        let str = maps.substringFromIndex(indexRange.endIndex)
                        if let indexRangeBracket = str.rangeOfString(")") {
                            let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                            let route = RouteMap()
                            route.points = str2.removeTabs()
                            train.routesMap.append(route)
                            maps = maps.substringFromIndex(indexRange.endIndex)
                        }
                    } else {
                        loops = false
                    }
                }
                
                if let inputNode = bodyNode?.findChildTags("tbody").first {
                    let nodes = inputNode.findChildTags("tr")
                    for node in nodes {
                        let route = RouteTUTU()
                        
                        let href = node.findChildTags("a").first
                        route.name = href!.contents.removeTabs()
                        route.code = href!.getAttributeNamed("href")
                        
                        let tdNodes = node.findChildTags("td")
                        
                        println(tdNodes[3].contents.removeTabs())
                        route.prib       = tdNodes[3].contents.removeTabs()
                        route.stojanka   = tdNodes[4].contents.removeTabs()
                        route.otpr       = tdNodes[5].contents.removeTabs()
                        route.kilometraz = tdNodes[6].contents.removeTabs()
                        route.v_puti     = tdNodes[7].contents.removeTabs()
                        
                        
                        train.routesTUTU.append(route)
                    }
                }
            }
            sleep(7)
        }
        
    }
}

func updateSchedule () {

    let trains = realm.objects(TrainNP)
    //    let train = trains.last
    
    for train in trains {
        if train.routeMap.isEmpty {
            println(train.np)
            
            realm.write {
                realm.delete(train.routesTUTU)
                realm.delete(train.routesMap)
            }
            
            let str = "http://www.tutu.ru/poezda/view_d.php?np=" + train.np
            var request = NSURLRequest(URL: NSURL(string: str)!)
            var response: NSURLResponse?
            var error: NSErrorPointer = nil
            var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error)
            var reply = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let html = reply as! String
            
            var err : NSError?
            var parser     = HTMLParser(html: html, error: &err)
            if err != nil {
                println(err)
                exit(1)
            }
            
            var bodyNode = parser.body
            let content = bodyNode?.contents
            
            if (content?.rangeOfString("captcha") != nil) {
                sleep(500)
            }
            
            realm.write {
                
                if let inputNodes = bodyNode?.findChildTags("h1") {
                    train.name = inputNodes.first!.contents.removeTabs()
                }
                
                
                if let indexRange = content!.rangeOfString("schedule: ") {
                    let str = content!.substringFromIndex(indexRange.endIndex)
                    if let indexRangeBracket = str.rangeOfString("]") {
                        let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                        train.schedule = str2.removeTabs()
                    }
                }
                if let indexRange = content!.rangeOfString("addPolyline( ") {
                    let str = content!.substringFromIndex(indexRange.endIndex)
                    if let indexRangeBracket = str.rangeOfString("]") {
                        let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                        train.routeMap = str2.removeTabs()
                    }
                }
                
                var maps = content!
                var loops = true
                while loops {
                    if let indexRange = maps.rangeOfString("addMarker") {
                        let str = maps.substringFromIndex(indexRange.endIndex)
                        if let indexRangeBracket = str.rangeOfString(")") {
                            let str2 = str.substringToIndex(indexRangeBracket.startIndex)
                            let route = RouteMap()
                            route.points = str2.removeTabs()
                            train.routesMap.append(route)
                            maps = maps.substringFromIndex(indexRange.endIndex)
                        }
                    } else {
                        loops = false
                    }
                }
                
                if let inputNode = bodyNode?.findChildTags("tbody").first {
                    let nodes = inputNode.findChildTags("tr")
                    for node in nodes {
                        let route = RouteTUTU()
                        
                        let href = node.findChildTags("a").first
                        route.name = href!.contents.removeTabs()
                        route.code = href!.getAttributeNamed("href")
                        
                        let tdNodes = node.findChildTags("td")
                        
                        println(tdNodes[3].contents.removeTabs())
                        route.prib       = tdNodes[3].contents.removeTabs()
                        route.stojanka   = tdNodes[4].contents.removeTabs()
                        route.otpr       = tdNodes[5].contents.removeTabs()
                        route.kilometraz = tdNodes[6].contents.removeTabs()
                        route.v_puti     = tdNodes[7].contents.removeTabs()
                        
                        
                        train.routesTUTU.append(route)
                    }
                }
            }
            sleep(7)
        }
        
    }
}



func trainParse() {
    
    for j in 16...19 {
        
        
        for i in 1...50 {
            
            let ind = i + j * 50
            println(ind)
            let str = "http://www.tutu.ru/poezda/search_train.php?train=" + String(ind)
            var request = NSURLRequest(URL: NSURL(string: str)!)
            var response: NSURLResponse?
            var error: NSErrorPointer = nil
            var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error)
            var reply = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let html = reply as! String
            //                println(html)
            
            var err : NSError?
            var parser     = HTMLParser(html: html, error: &err)
            if err != nil {
                println(err)
                exit(1)
            }
            
            var bodyNode = parser.body
            
            realm.beginWrite()
            if let inputNodes = bodyNode?.findChildTags("a") {
                for node in inputNodes {
                    let href = node.getAttributeNamed("href")
                    if let indexRange = href.rangeOfString("np=") {
                        let number = href.substringFromIndex(indexRange.endIndex)
                        let train = TrainNP()
                        train.np = number
                        realm.add(train, update: true)
                    }
                    
                }
            }
            realm.commitWrite()
            sleep(10)
            
        }
        sleep(120)
    }
}

extension String {
    func removeTabs() -> String {
        return self.stringByReplacingOccurrencesOfString("\t", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("\r", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}