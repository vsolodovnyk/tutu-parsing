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

func correctBrokenStationsInRoutes (brokenStation:[String]) {
    let routes = realm.objects(RouteTUTU)
    for (index, route) in enumerate(routes) {
        if route.prib.isEmpty {
            var nextRoute = routes[index + 1]
            let currentStations = realm.objects(Station).filter("code == \(route.code)")
            let nextStations = realm.objects(Station).filter("code == \(nextRoute.code)")
            
            if let currentStation = currentStations.first, let nextStation = nextStations.first {
                if route.kilometraz == nextRoute.kilometraz {
                    for broken in brokenStation {
                        if route.code == broken {
                            realm.write {
                                let nameTemp = route.name
                                let pribTemp = route.prib
                                let otprTemp = route.otpr
                                let kilometrazTemp = route.kilometraz
                                let codeTemp = route.code
                                let stojankaTemp = route.stojanka
                                let v_putiTemp = route.v_puti
                                
                                
                                route.name = nextRoute.name
                                route.prib = nextRoute.prib
                                route.otpr = nextRoute.otpr
                                route.kilometraz = nextRoute.kilometraz
                                route.code = nextRoute.code
                                route.stojanka = nextRoute.stojanka
                                route.v_puti = nextRoute.v_puti
                                
                                routes[index + 1].name = nameTemp
                                routes[index + 1].prib = pribTemp
                                routes[index + 1].otpr = otprTemp
                                routes[index + 1].kilometraz = kilometrazTemp
                                routes[index + 1].code = codeTemp
                                routes[index + 1].stojanka = stojankaTemp
                                routes[index + 1].v_puti = v_putiTemp
                                
                                //                            println(routes[index + 1].name)
                                
                                for train in route.trains {
                                    println("начальная в  \(train.np)")
                                }
                            }
                        }
                    }
                   
                }
            }
        }
        if route.otpr.isEmpty {
            var nextRoute = routes[index - 1]
            let currentStations = realm.objects(Station).filter("code == \(route.code)")
            let nextStations = realm.objects(Station).filter("code == \(nextRoute.code)")
            
            if let currentStation = currentStations.first, let nextStation = nextStations.first {
                if route.prib == nextRoute.prib {
                    for broken in brokenStation {

                        if route.code == broken {
                            realm.write {
                                let nameTemp = route.name
                                let pribTemp = route.prib
                                let otprTemp = route.otpr
                                let kilometrazTemp = route.kilometraz
                                let codeTemp = route.code
                                let stojankaTemp = route.stojanka
                                let v_putiTemp = route.v_puti
                                
                                route.name = nextRoute.name
                                route.prib = nextRoute.prib
                                route.otpr = nextRoute.otpr
                                route.kilometraz = nextRoute.kilometraz
                                route.code = nextRoute.code
                                route.stojanka = nextRoute.stojanka
                                route.v_puti = nextRoute.v_puti
                                
                                routes[index - 1].name = nameTemp
                                routes[index - 1].prib = pribTemp
                                routes[index - 1].otpr = otprTemp
                                routes[index - 1].kilometraz = kilometrazTemp
                                routes[index - 1].code = codeTemp
                                routes[index - 1].stojanka = stojankaTemp
                                routes[index - 1].v_puti = v_putiTemp
                                
                                //                            println(routes[index + 1].name)
                                
                                for train in route.trains {
                                    println("конечная в  \(train.np)")
                               }
                            }
                        }
                    }
                }
            }
        }

    }
}

func printRelatedStations () {
    let stations = realm.objects(Station)
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
            station.name_ru = route.name
            station.code = route.code.toInt()!
            realm.add(station, update: true)
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
    let routes = realm.objects(RouteTUTU)
    
    realm.write {
        for (index, route) in enumerate(routes) {
            let flagLast = index == routes.count - 1 ? false : route.prib == routes[index + 1].prib

            if route.prib.isEmpty {
                
                let nextRoute = routes[index + 1]
                let currentStations = realm.objects(Station).filter("code == \(route.code)")
                let nextStations = realm.objects(Station).filter("code == \(nextRoute.code)")

                if let currentStation = currentStations.first, let nextStation = nextStations.first {
                    if route.kilometraz == nextRoute.kilometraz {
                        var isAlready = false
                        for relSt in nextStation.relatedStations {
                            if currentStation.code == relSt.code {
                                isAlready = true
                            }
                        }
                        if !isAlready {
                            nextStation.relatedStations.append(currentStation)
                        }
                    }
                }
            }
            
//            let flagFirst = index < 1 ? false : route.otpr == routes[index - 1].otpr
//            
//            if route.otpr.isEmpty || flagFirst {
//                
//                let nextRoute = routes[index - 1]
//                let currentStations = realm.objects(Station).filter("code == \(route.code)")
//                let nextStations = realm.objects(Station).filter("code == \(nextRoute.code)")
//                
//                if let currentStation = currentStations.first, let nextStation = nextStations.first {
//                    if route.kilometraz == nextRoute.kilometraz {
//                        var isAlready = false
//                        for relSt in nextStation.relatedStations {
//                            if currentStation.code == relSt.code {
//                                isAlready = true
//                            }
//                        }
//                        if !isAlready {
//                            nextStation.relatedStations.append(currentStation)
//                        }
//                    }
//                }
//            }

        }
    }
    println("Finish write Station")
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

func qw () {
    
    Alamofire.request(.GET, "http://www.tutu.ru/poezda/search_train.php", parameters: ["train": 1 ])
        .responseString { (request, response, string, error) in
            
            let html = string
            //                println(html)
            
            var err : NSError?
            var parser     = HTMLParser(html: html!, error: &err)
            if err != nil {
                //                        println(err)
                exit(1)
            }
            
            var bodyNode = parser.body
            
            realm.beginWrite()
            if let inputNodes = bodyNode?.findChildTags("a") {
                for node in inputNodes {
                    //                            println(node.contents)
                    
                    let href = node.getAttributeNamed("href")
                    if let indexRange = href.rangeOfString("np=") {
                        let number = href.substringFromIndex(indexRange.endIndex)
                        //                                println(number)
                        let train = TrainNP()
                        train.np = number
                        realm.add(train, update: true)
                    }
                    
                }
            }
            realm.commitWrite()
            
    }
    
}

extension String {
    func removeTabs() -> String {
        return self.stringByReplacingOccurrencesOfString("\t", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("\r", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
}