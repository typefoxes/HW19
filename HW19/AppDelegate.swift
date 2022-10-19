import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    let gcmMessageIDKey = "gcm.message_id"
    let popupText = "popupText"
    let popupButton = "popupButton"
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
        guard let config = FirebaseOptions(contentsOfFile: path!)
        else {
            fatalError("Can't find –> GoogleService-Info.plist")
        }
        FirebaseApp.configure(options: config)
        

        InstanceID.instanceID().instanceID { (result, error) in
            guard (application.windows.first!.rootViewController as? ViewController) != nil else { return }
            if let error = error {
                print("\n= = = = = = Error fetching remote instance ID: = = = = = =")
                print("\(error.localizedDescription)")
                print("= = = = = = = = = = = = = = = = = = = = = = = =\n")
            } else if let result = result {
                print("\n= = = = = = Remote InstanceID token: = = = = = =")
                print("\(result.token)")
                print("= = = = = = = = = = = = = = = = = = = = = = = = =\n")
                
                guard let vc = application.windows.first!.rootViewController as? ViewController else { return }
                vc.statusToken.text = "токен получен"
                vc.statusToken.textColor = UIColor.systemGreen
                
                vc.tokenLabel.text = result.token
                vc.tokenLabel.font = .systemFont(ofSize: 12)
            }
        }
        
        Messaging.messaging().shouldEstablishDirectChannel = true
        Messaging.messaging().delegate = self
        listenForDirectChannelStateChanges()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler:{ success, error in
                guard error == nil else {
                    fatalError("requestAuthorization error \(error!.localizedDescription)")
                }
            })
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        
        return true
    }
    

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let vc = application.windows.first!.rootViewController as? ViewController else { return }
        
        if let message_id = userInfo[self.gcmMessageIDKey] {
            print("\n Message ID: \(message_id)")
            guard let result = message_id as? String else { return }
            

            vc.messageID_label.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.messageID.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.messageID.text = result
        }
        
        if let popupText = userInfo[popupText] {
            guard let result = popupText as? String else { return }
            vc.popupText_label.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.popupText.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.popupText.text = result
        }
        
        if let popupButton = userInfo[popupButton] {
            guard let result = popupButton as? String else { return }
            vc.popupButton_label.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.popupButton.layer.backgroundColor = UIColor.systemGreen.cgColor
            vc.popupButton.text = result
        }
        
        if let popupText = userInfo[popupText] as? String,
           let popupButton = userInfo[popupButton] as? String {

            
            DispatchQueue.main.async {
                vc.alert(popupText: popupText, popupButton: popupButton)
            }
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
        guard let prettyPrinted = remoteMessage.appData.jsonString
        else { assertionFailure("Received direct channel message, but could not parse as JSON: \(remoteMessage.appData)")
            return
        }
        
        print("##################################################")
        print("Interpreting notification message payload:\n\(prettyPrinted)")
        print("##################################################")
        
        DispatchQueue.main.async {
            guard let vc = UIApplication.shared.windows.first!.rootViewController as? ViewController else { return }
            vc.remoteMessage.text = prettyPrinted
        }
    }
}
extension Dictionary {
    var jsonString: String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}
extension AppDelegate {
    func registerForNotifications(types: UIUserNotificationType) {
        if #available(iOS 10, *) {
            let options = types.authorizationOptions()
            UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
                if success {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
@available(iOS 10, *)
extension UIUserNotificationType {
    func authorizationOptions() -> UNAuthorizationOptions {
        var options: UNAuthorizationOptions = []
        if contains(.alert) {
            options.formUnion(.alert)
        }
        if contains(.sound) {
            options.formUnion(.sound)
        }
        if contains(.badge) {
            options.formUnion(.badge)
        }
        return options
    }
}
extension AppDelegate {
    func listenForDirectChannelStateChanges() {
        NotificationCenter.default
            .addObserver(self, selector: #selector(onMessagingDirectChannelStateChanged(_:)),
                         name: .MessagingConnectionStateChanged, object: nil)
    }
    
    @objc func onMessagingDirectChannelStateChanged(_ notification: Notification) {
        print("FCM Direct Channel Established: \(Messaging.messaging().isDirectChannelEstablished)")
    }
}
