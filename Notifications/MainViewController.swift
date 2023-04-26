//
//  MainViewController.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var notificationsStack: UIStackView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tableView: UITableView!
    
    var notificationManager: LocalNotificationManager!
    
    private var notifications: [LocalNotification] = [] {
        didSet {
            clearButton.isEnabled = notifications.count > 0
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
            selector: #selector(checkAuthorizationStatus),
            name: .sceneWillEnterForeground,
            object: nil
        )

        notificationManager = LocalNotificationManager()
        notificationManager.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - IBActions
    
    @IBAction func clearNotificationsButtonTapped(_ sender: Any) {
        notificationManager.removeAllPendingRequests()
    }
    
    @IBAction func intervalNotificationButtonTapped(_ sender: UIButton) {
        var notification = LocalNotification(
            identifier: UUID().uuidString,
            title: "Interval Notification",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            timeInterval: 10,
            repeats: false
        )
        notification.subtitle = "Subtitle for Interval Notification"
        notification.bundleImageName = "iOS-15.jpg"
        
        notificationManager.schedule(localNotification: notification)
    }
    
    @IBAction func calendarNotificationButtonTapped(_ sender: UIButton) {
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: datePicker.date
        )
        
        let notification = LocalNotification(
            identifier: UUID().uuidString,
            title: "Calendar Notification",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            dateComponents: dateComponents,
            repeats: true
        )
        
        notificationManager.schedule(localNotification: notification)
    }
    
    @objc private func checkAuthorizationStatus() {
        notificationManager.requestAuthorization { [weak self] isGranted, error in
            if let error {
                print(error.localizedDescription)
            } else if isGranted {
                self?.notificationsStack.isHidden = false
            } else {
                self?.presentAlertForOpenSettings()
                self?.notificationsStack.isHidden = true
            }
        }
        
        notificationManager.getPendingRequests { [weak self] requests in
            self?.notifications = requests.map(LocalNotification.init)
        }
    }
    
    private func presentAlertForOpenSettings() {
        
        let title = "\"Notifications\" Would Like to Send You Notifications"
        let message = "Notifications may include alerts, sounds, and icon badges. These can be configured in Settings."
       
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let disallowAction = UIAlertAction(title: "Don't Allow", style: .default)
        let allowAction = UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
            self?.notificationManager.openSettings()
        }
        alert.addAction(disallowAction)
        alert.addAction(allowAction)
        
        present(alert, animated: true)
    }
}


// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let notification = notifications[indexPath.row]
        
        cell.textLabel?.text = notification.title
        cell.detailTextLabel?.text = notification.body
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let identifier = notifications[indexPath.row].identifier
            notificationManager.removePendingRequests(withIdentifier: identifier)
        }
    }
}

// MARK: - LocalNotificationManagerDelegate

extension MainViewController: LocalNotificationManagerDelegate {
    
    func localNotificationManager(_ localNotificationManager: LocalNotificationManager, willChangePendingNotificationRequests notificationRequests: [UNNotificationRequest]) {
        notifications = notificationRequests.map(LocalNotification.init)
    }
}
