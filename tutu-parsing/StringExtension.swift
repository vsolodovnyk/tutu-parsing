//
//  Extensions.swift
//  Schedule
//
//  Created by Valerii Solodovnyk on 23.04.15.
//  Copyright (c) 2015 Valerii Solodovnyk. All rights reserved.
//

import Foundation

extension String
{
    var length: Int {
        get {
            return count(self)
        }
    }
    
    func contains(s: String) -> Bool
    {
        return (self.rangeOfString(s) != nil) ? true : false
    }
    
    func replace(target: String, withString: String) -> String
    {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    subscript (i: Int) -> Character
        {
        get {
            let index = advance(startIndex, i)
            return self[index]
        }
    }
    
    subscript (r: Range<Int>) -> String
        {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(self.startIndex, r.endIndex - 1)
            
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
    
    func subString(startIndex: Int, length: Int) -> String
    {
        var start = advance(self.startIndex, startIndex)
        var end = advance(self.startIndex, startIndex + length)
        return self.substringWithRange(Range<String.Index>(start: start, end: end))
    }
    
    func indexOf(target: String) -> Int
    {
        var range = self.rangeOfString(target)
        if let range = range {
            return distance(self.startIndex, range.startIndex)
        } else {
            return -1
        }
    }
    
    func indexOf(target: String, startIndex: Int) -> Int
    {
        var startRange = advance(self.startIndex, startIndex)
        
        var range = self.rangeOfString(target, options: NSStringCompareOptions.LiteralSearch, range: Range<String.Index>(start: startRange, end: self.endIndex))
        
        if let range = range {
            return distance(self.startIndex, range.startIndex)
        } else {
            return -1
        }
    }
    
    func lastIndexOf(target: String) -> Int
    {
        var index = -1
        var stepIndex = self.indexOf(target)
        while stepIndex > -1
        {
            index = stepIndex
            if stepIndex + target.length < self.length {
                stepIndex = indexOf(target, startIndex: stepIndex + target.length)
            } else {
                stepIndex = -1
            }
        }
        return index
    }
    
    func isMatch(regex: String, options: NSRegularExpressionOptions) -> Bool
    {
        var error: NSError?
        var exp = NSRegularExpression(pattern: regex, options: options, error: &error)
        
        if let error = error {
            println(error.description)
        }
        var matchCount = exp!.numberOfMatchesInString(self, options: nil, range: NSMakeRange(0, self.length))
        return matchCount > 0
    }
    
    func getMatches(regex: String, options: NSRegularExpressionOptions) -> [NSTextCheckingResult]
    {
        var error: NSError?
        var exp = NSRegularExpression(pattern: regex, options: options, error: &error)
        
        if let error = error {
            println(error.description)
        }
        var matches = exp!.matchesInString(self, options: nil, range: NSMakeRange(0, self.length))
        return matches as! [NSTextCheckingResult]
    }
    
    private var vowels: [String]
        {
        get
        {
            return ["a", "e", "i", "o", "u"]
        }
    }
    
    private var consonants: [String]
        {
        get
        {
            return ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
        }
    }
    
    func pluralize(count: Int) -> String
    {
        if count == 1 {
            return self
        } else {
            var lastChar = self.subString(self.length - 1, length: 1)
            var secondToLastChar = self.subString(self.length - 2, length: 1)
            var prefix = "", suffix = ""
            
            if lastChar.lowercaseString == "y" && vowels.filter({x in x == secondToLastChar}).count == 0 {
                prefix = self[0...self.length - 1]
                suffix = "ies"
            } else if lastChar.lowercaseString == "s" || (lastChar.lowercaseString == "o" && consonants.filter({x in x == secondToLastChar}).count > 0) {
                prefix = self[0...self.length]
                suffix = "es"
            } else {
                prefix = self[0...self.length]
                suffix = "s"
            }
            
            return prefix + (lastChar != lastChar.uppercaseString ? suffix : suffix.uppercaseString)
        }
    }
}


extension String {
    var hexaToInt      : Int    { return Int(strtoul(self, nil, 16))    }
    var hexaToDouble   : Double { return Double(strtoul(self, nil, 16)) }
    var hexaToBinary   : String { return String(hexaToInt, radix: 2)    }
    var intToHexa      : String { return String(toInt()!, radix: 16)    }
    var intToBinary    : String { return String(toInt()!, radix: 2)     }
    var binaryToInt    : Int    { return Int(strtoul(self, nil, 2))     }
    var binaryToDouble : Double { return Double(strtoul(self, nil, 2))  }
    var binaryToHexa   : String { return String(binaryToInt, radix: 16) }
    
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
    
    func substring (fromString: String, toString: String) -> String? {
        var name = self
        if let startIndex = name.rangeOfString(fromString)?.endIndex {
            name = name.substringFromIndex(startIndex)
            if let endIndex = name.rangeOfString(toString)?.startIndex {
                name = name.substringToIndex(endIndex)
                return name
            }
        }
        return nil
    }
    
}


// Usage
//"Awesome".contains("me") == true
//"Awesome".contains("Aw") == true
//"Awesome".contains("so") == true
//"Awesome".contains("Dude") == false
//
//"ReplaceMe".replace("Me", withString: "You") == "ReplaceYou"
//"MeReplace".replace("Me", withString: "You") == "YouReplace"
//"ReplaceMeNow".replace("Me", withString: "You") == "ReplaceYouNow"
//
//"0123456789"[0] == "0"
//"0123456789"[5] == "5"
//"0123456789"[9] == "9"
//
//"0123456789"[5...6] == "5"
//"0123456789"[0...1] == "0"
//"0123456789"[8...9] == "8"
//"0123456789"[1...5] == "1234"
//"Reply"[0...4] == "Repl"
//"Hello, playground"[0...5] == "Hello"
//"Coolness"[4...7] == "nes"
//
//"Awesome".indexOf("nothin") == -1
//"Awesome".indexOf("Awe") == 0
//"Awesome".indexOf("some") == 3
//"Awesome".indexOf("e", startIndex: 3) == 6
//"Awesome".lastIndexOf("e") == 6
//"Cool".lastIndexOf("o") == 2
//
//var emailRegex = "[a-z_\\-\\.]+@[a-z_\\-\\.]{3,}"
//"email@test.com".isMatch(emailRegex, options: NSRegularExpressionOptions.CaseInsensitive) == true
//"email-test.com".isMatch(emailRegex, options: NSRegularExpressionOptions.CaseInsensitive) == false
//
//var testText = "email@test.com, other@test.com, yet-another@test.com"
//var matches = testText.getMatches(emailRegex, options: NSRegularExpressionOptions.CaseInsensitive)
//matches.count == 3
//testText.subString(matches[0].range.location, length: matches[0].range.length) == "email@test.com"
//testText.subString(matches[1].range.location, length: matches[1].range.length) == "other@test.com"
//testText.subString(matches[2].range.location, length: matches[2].range.length) == "yet-another@test.com"
//
//"Reply".pluralize(0) == "Replies"
//"Reply".pluralize(1) == "Reply"
//"Reply".pluralize(2) == "Replies"
//"REPLY".pluralize(3) == "REPLIES"
//"Horse".pluralize(2) == "Horses"
//"Boy".pluralize(2) == "Boys"
//"Cut".pluralize(2) == "Cuts"
//"Boss".pluralize(2) == "Bosses"
//"Domino".pluralize(2) == "Dominoes"

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.toDay() === rhs.toDay() || lhs.compare(rhs.toDay()) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.toDay().compare(rhs.toDay()) == .OrderedAscending
}

extension NSDate: Comparable {
    func toDay() -> NSDate{
     return NSCalendar.currentCalendar().startOfDayForDate(self)
    }
}


