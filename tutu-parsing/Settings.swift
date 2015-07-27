//
//  Settings.swift
//  Schedule 2.0
//
//  Created by Valerii Solodovnyk on 11.07.15.
//  Copyright (c) 2015 Valerii Solodovnyk. All rights reserved.
//

import Foundation


func getCurrentLanguage () -> String {
    return NSLocale.preferredLanguages().first as! String
}
var currentLanguage = getCurrentLanguage()