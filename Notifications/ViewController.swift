//
//  ViewController.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var enableNotificationsButton: UIButton!
    @IBOutlet weak var notificationsStack: UIStackView!
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
            selector: #selector(sceneWillEnterForeground),
            name: .sceneWillEnterForeground,
            object: nil
        )
        
        notificationManager = LocalNotificationManager()
        notificationManager.delegate = self
    }
    
    @IBAction func enableNotificationsButtonTapped(_ sender: UIButton) {
        notificationManager.openSettings()
    }
    
    @IBAction func intervalNotificationButtonTapped(_ sender: UIButton) {
        let notification = LocalNotification(
            identifier: UUID().uuidString,
            title: "Lorem Title",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            timeInterval: 60,
            repeats: true
        )
        
        notificationManager.schedule(localNotification: notification)
    }
    
    @IBAction func calendarNotificationButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func clearNotificationsButtonTapped(_ sender: Any) {
        notificationManager.removeAllPendingRequests()
    }
    
    @objc private func sceneWillEnterForeground() {
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
        
        notificationManager.getPendingRequests { [weak self] requests in
            self?.notifications = requests.map(LocalNotification.init)
        }
    }
}


// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
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

extension ViewController: UITableViewDelegate {
    
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

extension ViewController: LocalNotificationManagerDelegate {
    
    func localNotificationManager(_ localNotificationManager: LocalNotificationManager, willChangePendingNotificationRequests notificationRequests: [UNNotificationRequest]) {
        notifications = notificationRequests.map(LocalNotification.init)
    }
}
