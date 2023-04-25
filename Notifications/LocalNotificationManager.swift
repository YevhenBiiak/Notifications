//
//  LocalNotificationManager.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit
import NotificationCenter

class LocalNotificationManager {
    
    enum AuthorizationStatus { case notDetermined, denied, authorized }
    
    var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    
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
}
