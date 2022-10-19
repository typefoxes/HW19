import UIKit
import Messages
import FirebaseMessaging
import FirebaseInstanceID

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var statusToken: UILabel!
    @IBOutlet weak var tokenLabel: UILabel!

    @IBOutlet weak var messageID_label: UILabel!
    @IBOutlet weak var messageID: UILabel!
 
    @IBOutlet weak var popupText_label: UILabel!
    @IBOutlet weak var popupText: UILabel!
 
    @IBOutlet weak var popupButton_label: UILabel!
    @IBOutlet weak var popupButton: UILabel!
    
    @IBOutlet weak var remoteMessage_label: UILabel!
    @IBOutlet weak var remoteMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Messaging.messaging().subscribe(toTopic: "weather") { error in
            print("Subscribed to weather topic")
        }
    }
    
    public func alert(popupText: String, popupButton: String) {
        let alertController = UIAlertController(title: "Push notification", message: "", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "\(popupText)", style: .default) { (action:UIAlertAction) in
            print("popupText tap")
        }
        
        let action2 = UIAlertAction(title: "\(popupButton)", style: .default) { (action:UIAlertAction) in
            print("popupButton tap")
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
    }
}
