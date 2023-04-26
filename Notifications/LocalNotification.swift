//
//  LocalNotification.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import Foundation
import NotificationCenter

struct LocalNotification {
    enum ScheduleType { case interval, calendar }
    
    let identifier: String
    let scheduleType: ScheduleType
    let title: String
    var subtitle: String?
    let body: String
    var bundleImageName: String?
    var userInfo: [AnyHashable: Any]?
    var categoryID: String?
    var timeInterval: TimeInterval?
    var dateComponents: DateComponents?
    let repeats: Bool
    
    init(identifier: String,
         title: String,
         body: String,
         timeInterval: TimeInterval,
         repeats: Bool
    ) {
        self.identifier = identifier
        self.scheduleType = .interval
        self.title = title
        self.body = body
        self.timeInterval = timeInterval
        self.repeats = repeats
    }
    
    init(identifier: String,
         title: String,
         body: String,
         dateComponents: DateComponents,
         repeats: Bool
    ) {
        self.identifier = identifier
        self.scheduleType = .calendar
        self.title = title
        self.body = body
        self.dateComponents = dateComponents
        self.repeats = repeats
    }
}

extension LocalNotification {
    
    init?(_ notificationRequest: UNNotificationRequest) {
        self.identifier = notificationRequest.identifier
        self.title = notificationRequest.content.title
        self.body = notificationRequest.content.body
        self.userInfo = notificationRequest.content.userInfo
        
        if let timeIntervalTrigger = notificationRequest.trigger as? UNTimeIntervalNotificationTrigger {
            self.scheduleType = .interval
            self.timeInterval = timeIntervalTrigger.timeInterval
            self.repeats = timeIntervalTrigger.repeats
        } else if let calendarTrigger = notificationRequest.trigger as? UNCalendarNotificationTrigger {
            self.scheduleType = .calendar
            self.dateComponents = calendarTrigger.dateComponents
            self.repeats = calendarTrigger.repeats
        } else {
            return nil
        }
    }
}
