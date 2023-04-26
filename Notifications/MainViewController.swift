//
//  MainViewController.swift
//  Notifications
//
//  Created by Yevhen Biiak on 25.04.2023.
//

import UIKit

enum TargetViewController: String {
    static let key = String(describing: Self.self)
    case promotion, subscription
}

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
            timeInterval: 3,
            repeats: false
        )
        notification.subtitle = "Subtitle for Interval Notification"
        notification.bundleImageName = "iOS-15.jpg"
        notification.userInfo = [TargetViewController.key: TargetViewController.subscription.rawValue]
        notification.categoryID = NotificationCategory.identifier
        
        notificationManager.schedule(localNotification: notification)
    }
    
    @IBAction func calendarNotificationButtonTapped(_ sender: UIButton) {
        let dateComponents = Calendar.current.dateComponents(
            [.month, .day, .hour, .minute],
            from: datePicker.date
        )
        
        var notification = LocalNotification(
            identifier: UUID().uuidString,
            title: "Calendar Notification",
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            dateComponents: dateComponents,
            repeats: true
        )
        notification.bundleImageName = "iOS-15.jpg"
        notification.userInfo = [TargetViewController.key: TargetViewController.promotion.rawValue]
        
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
            self?.notifications = requests.compactMap(LocalNotification.init)
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
        if notification.scheduleType == .interval {
            cell.detailTextLabel?.text = "\(Int(notification.timeInterval!)) seconds"
        } else if notification.scheduleType == .calendar {
            let date = Calendar.current.date(from: notification.dateComponents!)
            cell.detailTextLabel?.text = date?.formatted("MMMM d HH:mm")
        }
        
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
    
    func localNotificationManager(
        _ localNotificationManager: LocalNotificationManager,
        willChangePendingNotification notifications: [LocalNotification]
    ) {
        self.notifications = notifications
    }

    func localNotificationManager(
        _ localNotificationManager: LocalNotificationManager,
        didReceiveResponseTo notification: LocalNotification
    ) {
        guard let userInfo = notification.userInfo,
              let value = userInfo[TargetViewController.key] as? String,
              let targetViewController = TargetViewController(rawValue: value)
        else { return }
            
        switch targetViewController {
        case .promotion:
            let viewController = UIStoryboard.main.instance(of: PromotionViewController.self)
            present(viewController, animated: true)
        case .subscription:
            let viewController = UIStoryboard.main.instance(of: SubscriptionViewCotroller.self)
            present(viewController, animated: true)
        }
    }
}

// MARK: - Extension UIStoryboard

extension UIStoryboard {
    static let main = UIStoryboard(name: "Main", bundle: nil)
    
    func instance<T: UIViewController>(of viewController: T.Type) -> T {
        let identifier = String(describing: viewController.self)
        return instantiateViewController(withIdentifier: identifier) as! T
    }
}

// MARK: - Extension Date

extension Date {
    func formatted(_ format: String) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: self)
    }
}
