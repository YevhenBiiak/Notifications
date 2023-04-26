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
    
    init(_ notificationRequest: UNNotificationRequest) {
        let trigger = notificationRequest.trigger as? UNTimeIntervalNotificationTrigger
        self.identifier = notificationRequest.identifier
        self.scheduleType = trigger?.timeInterval != nil ? .interval : .calendar
        self.title = notificationRequest.content.title
        self.body = notificationRequest.content.body
        self.repeats = notificationRequest.trigger?.repeats ?? false
    }
}
