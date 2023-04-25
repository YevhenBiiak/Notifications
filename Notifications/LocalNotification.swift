//
//  LocalNotification.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import Foundation
import NotificationCenter

struct LocalNotification {
    let identifier: String
    let title: String
    let body: String
    let timeInterval: TimeInterval
    let repeats: Bool
}

extension LocalNotification {
    
    init(_ notificationRequest: UNNotificationRequest) {
        self.identifier = notificationRequest.identifier
        self.title = notificationRequest.content.title
        self.body = notificationRequest.content.body
        self.timeInterval = (notificationRequest.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval ?? 0
        self.repeats = notificationRequest.trigger?.repeats ?? false
    }
}
