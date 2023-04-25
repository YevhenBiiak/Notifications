//
//  ViewController.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var enableNotificationsButton: UIButton!
    @IBOutlet weak var notificationsStack: UIStackView!
    
    var notificationManager = LocalNotificationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(checkAuthorization),
            name: .sceneWillEnterForeground,
            object: nil
        )
    }
    
    @IBAction func enableNotificationsButtonTapped(_ sender: UIButton) {
        notificationManager.openSettings()
    }
    
    @IBAction func intervalNotificationButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func calendarNotificationButtonTapped(_ sender: UIButton) {
        
    }
    
    @objc private func checkAuthorization() {
        notificationManager.requestAuthorization { [weak self] isGranted, error in
            if let error {
                print(error.localizedDescription)
            } else if isGranted {
                self?.enableNotificationsButton.isHidden = true
                self?.notificationsStack.isHidden = false
            } else {
                self?.enableNotificationsButton.isHidden = false
                self?.notificationsStack.isHidden = true
            }
        }
    }
}
