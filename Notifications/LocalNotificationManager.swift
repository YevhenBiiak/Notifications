//
//  LocalNotificationManager.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit
import NotificationCenter

protocol LocalNotificationManagerDelegate: AnyObject {
    func localNotificationManager(_ localNotificationManager: LocalNotificationManager, willChangePendingNotificationRequests notificationRequests: [UNNotificationRequest])
}

class LocalNotificationManager: NSObject {
    
    enum AuthorizationStatus { case notDetermined, denied, authorized }
    
    var authorizationStatus: AuthorizationStatus = .notDetermined
    weak var delegate: LocalNotificationManagerDelegate?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
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
            self.delegate?.localNotificationManager(self, willChangePendingNotificationRequests: requests)
        }
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
}
