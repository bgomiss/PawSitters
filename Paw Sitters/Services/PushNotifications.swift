//
//  PushNotifications.swift
//  Paw Sitters
//
//  Registers the device for push notifications and stores its Firebase Cloud
//  Messaging token in `fcmTokens/{uid}`. The Cloud Functions in `functions/`
//  read those tokens to notify users about new messages, applications and reviews.
//

import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push registration failed: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        PushNotifications.save(token: fcmToken)
    }

    // Show notifications as banners even while the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}

enum PushNotifications {
    private static var collection: CollectionReference {
        Firestore.firestore().collection("fcmTokens")
    }

    /// Asks for permission (once) and registers with APNs; call after the user signs in.
    static func registerForSignedInUser() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            // The token may already exist from an earlier launch; make sure it's stored for this user.
            Messaging.messaging().token { token, _ in
                save(token: token)
            }
        }
    }

    static func save(token: String?) {
        guard let token, let uid = Auth.auth().currentUser?.uid else { return }
        collection.document(uid).setData([
            "tokens": FieldValue.arrayUnion([token]),
            "updatedAt": Timestamp(date: Date())
        ], merge: true) { error in
            if let error = error {
                print("Failed to save push token: \(error.localizedDescription)")
            }
        }
    }

    /// Stops notifications for this device; call before signing out.
    static func unregisterCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Messaging.messaging().token { token, _ in
            guard let token else { return }
            collection.document(uid).updateData(["tokens": FieldValue.arrayRemove([token])])
        }
    }
}
