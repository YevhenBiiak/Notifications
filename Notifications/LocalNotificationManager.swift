//
//  LocalNotificationManager.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit
import NotificationCenter

protocol LocalNotificationManagerDelegate: AnyObject {
    func localNotificationManager(_ localNotificationManager: LocalNotificationManager, willChangePendingNotification notifications: [LocalNotification])
    func localNotificationManager(_ localNotificationManager: LocalNotificationManager, didReceiveResponseTo notification: LocalNotification)
}

enum NotificationCategory {
    static let identifier: String = "Snooze"
    enum Action: String {
        case snooze10
        case snooze60
    }
}

class LocalNotificationManager: NSObject {
    
    enum AuthorizationStatus { case notDetermined, denied, authorized }
    
    var authorizationStatus: AuthorizationStatus = .notDetermined
    weak var delegate: LocalNotificationManagerDelegate?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        registerActions()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func requestAuthorization(_ completionHandler: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] didAllow, error in
            
            self?.authorizationStatus = didAllow ? .authorized : .denied
            
            DispatchQueue.main.async {
                completionHandler(didAllow, error)
            }
        }
    }
    
    func schedule(localNotification: LocalNotification) {
        
        let content = UNMutableNotificationContent()
        content.title = localNotification.title
        content.body = localNotification.body
        content.sound = .default
        
        if let subtitle = localNotification.subtitle {
            content.subtitle = subtitle
        }
        if let bundleImageName = localNotification.bundleImageName,
           let url = Bundle.main.url(forResource: bundleImageName, withExtension: ""),
           let attachment = try? UNNotificationAttachment(
              identifier: localNotification.identifier + bundleImageName,
              url: url) {
            content.attachments = [attachment]
        }
        if let userInfo = localNotification.userInfo {
            content.userInfo = userInfo
        }
        if let categoryID = localNotification.categoryID {
            content.categoryIdentifier = categoryID
        }
        var trigger: UNNotificationTrigger? = nil
        
        if let timeInterval = localNotification.timeInterval,
            localNotification.scheduleType == .interval {
            
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: localNotification.repeats
            )
        } else if let dateComponents = localNotification.dateComponents,
            localNotification.scheduleType == .calendar {
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: localNotification.repeats
            )
        }
        
        guard let trigger else { return }
        
        let request = UNNotificationRequest(
            identifier: localNotification.identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] _ in
            self?.notifyDelegate()
        }
    }
    
    func getPendingRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completionHandler(requests)
            }
        }
    }
    
    func removePendingRequests(withIdentifier id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notifyDelegate()
    }
    
    func removeAllPendingRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        notifyDelegate()
    }
    
    private func notifyDelegate() {
        getPendingRequests { requests in
            let notifications = requests.map(LocalNotification.init).compactMap({$0})
            self.delegate?.localNotificationManager(self, willChangePendingNotification: notifications)
        }
    }
    
    private func registerActions() {
        let snooz10Action = UNNotificationAction(
            identifier: NotificationCategory.Action.snooze10.rawValue,
            title: "Snooze 10 seconds"
        )
        let snooz60Action = UNNotificationAction(
            identifier: NotificationCategory.Action.snooze60.rawValue,
            title: "Snooze 60 seconds"
        )
        let category = UNNotificationCategory(
            identifier: NotificationCategory.identifier,
            actions: [snooz10Action, snooz60Action],
            intentIdentifiers: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else if #available(iOS 10.0, *) {
            completionHandler([.alert, .sound])
        }
        
        notifyDelegate()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let notification = LocalNotification(response.notification.request) else { return }
        delegate?.localNotificationManager(self, didReceiveResponseTo: notification)
        
        switch NotificationCategory.Action(rawValue: response.actionIdentifier) {
        case .snooze10:
            let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            notificationCenter.add(request)
            notifyDelegate()
        case .snooze60:
            let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            notificationCenter.add(request)
            notifyDelegate()
        case .none:
            break
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
}
