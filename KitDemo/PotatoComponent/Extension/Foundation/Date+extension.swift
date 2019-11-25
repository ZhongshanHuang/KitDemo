//
//  Date+extension.swift
//  weibo
//
//  Created by 黄山哥 on 2019/4/18.
//  Copyright © 2019 黄山哥. All rights reserved.
//

import Foundation

extension Date {
    
    var year: Int? {
        return Calendar.current.dateComponents([.year], from: self).year
    }
    
    var month: Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }
    
    var day: Int? {
        return Calendar.current.dateComponents([.day], from: self).day
    }
    
    var hour: Int? {
        return Calendar.current.dateComponents([.hour], from: self).hour
    }
    
    var minute: Int? {
        return Calendar.current.dateComponents([.minute], from: self).minute
    }
    
    var second: Int? {
        return Calendar.current.dateComponents([.second], from: self).second
    }

    var nanosecond: Int? {
        return Calendar.current.dateComponents([.second], from: self).nanosecond
    }
    
    var weekday: Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
    
    var weekdayOrdinal: Int? {
        return Calendar.current.dateComponents([.weekdayOrdinal], from: self).weekdayOrdinal
    }
    
    var weekOfMonth: Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: self).weekOfMonth
    }
    
    var weekOfYear: Int? {
        return Calendar.current.dateComponents([.weekOfYear], from: self).weekOfYear
    }
    
    var yearForWeekOfYear: Int? {
        return Calendar.current.dateComponents([.yearForWeekOfYear], from: self).yearForWeekOfYear
    }
    
    var quarter: Int? {
        return Calendar.current.dateComponents([.quarter], from: self).quarter
    }
    
    var isLeapMonth: Bool {
        return Calendar.current.dateComponents([.quarter], from: self).isLeapMonth ?? false
    }
    
    var isLeapYear: Bool {
        guard let year = self.year else { return false }
        return ((year % 400 == 0) || ((year % 100 != 0) && (year % 4 == 0)))
    }
    
    var isToday: Bool {
        if fabs(self.timeIntervalSinceNow) >= 60 * 60 * 24 { return false }
        return Date().day == self.day
    }
    
    var isYesterday: Bool {
        let added = dateByAddingDays(1)
        return added?.isToday ?? false
    }
    
    func dateByAddingYears(_ years: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = years
        return calendar.date(byAdding: components, to: self)
    }
    
    func dateByAddingMonths(_ months: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = months
        return calendar.date(byAdding: components, to: self)
    }
    
    func dateByAddingWeeks(_ weeks: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekOfYear = weeks
        return calendar.date(byAdding: components, to: self)
    }
    
    func dateByAddingDays(_ days: Int) -> Date? {
        let timeInterval = timeIntervalSinceReferenceDate + 86400 * Double(days)
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func dateByAddingHours(_ hours: Int) -> Date? {
        let timeInterval = timeIntervalSinceReferenceDate + 3600 * Double(hours)
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func dateByAddingMinutes(_ minutes: Int) -> Date? {
        let timeInterval = timeIntervalSinceReferenceDate + 60 * Double(minutes)
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func dateByAddingSeconds(_ seconds: Int) -> Date? {
        let timeInterval = timeIntervalSinceReferenceDate + Double(seconds)
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
}
