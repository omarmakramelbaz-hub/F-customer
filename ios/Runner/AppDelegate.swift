import UIKit
import Flutter
import GoogleMaps
import flutter_local_notifications
import FirebaseCore
import FirebaseMessaging
import FBSDKCoreKit
import GoogleSignIn
import ActivityKit

@available(iOS 16.1, *)
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    struct ContentState: Codable, Hashable {
        var orderId: String
        var orderStatus: String
        var restaurantName: String
        var updatedAt: Int
    }
    var id = UUID()
    var orderId: String
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var orderActivityChannel: FlutterMethodChannel?
    private var orderActivityTokenTasks: [String: Task<Void, Never>] = [:]
    private let liveActivityAppGroupId = "group.faskhaninja.liveactivities"
  
  override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        GMSServices.provideAPIKey("AIzaSyBDfirv6d7BiO-9YnsU5zCHEn9iM9iNtuM")
        GeneratedPluginRegistrant.register(with: self)
        configureOrderActivityChannel()
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted for debug handler")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)

    }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenParts = deviceToken.map { String(format: "%02x", $0) }
        let token = tokenParts.joined()
        print("APNS_TOKEN_REGISTERED => \(token)")
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("REMOTE_NOTIFICATION_RECEIVED => \(userInfo)")

        guard isLiveActivityPayload(userInfo) else {
            super.application(
                application,
                didReceiveRemoteNotification: userInfo,
                fetchCompletionHandler: completionHandler
            )
            return
        }

        guard #available(iOS 16.1, *) else {
            completionHandler(.noData)
            return
        }

        Task {
            let didUpdate = await updateLiveActivityFromPush(userInfo)
            completionHandler(didUpdate ? .newData : .noData)
        }
    }


    // Properties for MethodChannel handling
    // var flutterResult: FlutterResult?
    // var paymobPaymentKey: String?
    // var acceptSDK = AcceptSDK()

    // Google Sign-In URL handling - COMMENTED OUT
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let googleHandled = GIDSignIn.sharedInstance.handle(url)

        let facebookHandled = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

        return googleHandled || facebookHandled || super.application(app, open: url, options: options)
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if isLiveActivityPayload(userInfo) {
            completionHandler([])
            return
        }
        completionHandler(.alert) // shows banner even if app is in foreground
    }

    @available(iOS 16.1, *)
    private func updateLiveActivityFromPush(_ userInfo: [AnyHashable: Any]) async -> Bool {
        let payload = mergedLiveActivityPayload(userInfo)
        guard let orderId = extractOrderId(from: payload),
              let status = extractStatus(from: payload) else { return false }
        let matches = Activity<LiveActivitiesAppAttributes>.activities.filter { $0.attributes.orderId == orderId }
        for activity in matches {
            let state = orderActivityState(payload, previous: activity.contentState)
            if state.updatedAt > 0 && activity.contentState.updatedAt > state.updatedAt { continue }
            cacheOrderActivity(state, prefix: activity.attributes.id.uuidString)
            if isTerminalStatus(status) {
                await activity.end(using: state, dismissalPolicy: .after(Date().addingTimeInterval(120)))
            } else {
                await activity.update(using: state)
            }
        }
        return !matches.isEmpty
    }

    private func configureOrderActivityChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else { return }
        let channel = FlutterMethodChannel(name: "com.fasakhansta/order_activity", binaryMessenger: controller.binaryMessenger)
        orderActivityChannel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(nil); return }
            guard #available(iOS 16.1, *) else {
                result(call.method == "supported" ? false : nil)
                return
            }
            if call.method == "supported" {
                result(ActivityAuthorizationInfo().areActivitiesEnabled)
                return
            }
            guard let data = call.arguments as? [String: Any],
                  let orderId = self.extractOrderId(from: data) else {
                result(FlutterError(code: "invalid_order", message: "Missing order ID", details: nil))
                return
            }
            Task { @MainActor in
                let existing = Activity<LiveActivitiesAppAttributes>.activities.first { $0.attributes.orderId == orderId }
                let state = self.orderActivityState(data, previous: existing?.contentState)
                do {
                    if call.method == "sync" {
                        guard ActivityAuthorizationInfo().areActivitiesEnabled else { result(nil); return }
                        let activity: Activity<LiveActivitiesAppAttributes>
                        if let existing = existing {
                            activity = existing
                            if state.updatedAt == 0 || existing.contentState.updatedAt <= state.updatedAt {
                                await activity.update(using: state)
                            }
                        } else {
                            // iOS only allows local creation while the app is visible.
                            guard UIApplication.shared.applicationState == .active else { result(nil); return }
                            activity = try Activity.request(
                                attributes: LiveActivitiesAppAttributes(orderId: orderId),
                                contentState: state, pushType: .token)
                        }
                        self.cacheOrderActivity(state, prefix: activity.attributes.id.uuidString)
                        self.observeOrderActivityToken(activity)
                        result(self.orderActivitySnapshot(activity))
                    } else if call.method == "end" {
                        if let activity = existing {
                            self.cacheOrderActivity(state, prefix: activity.attributes.id.uuidString)
                            let immediate = data["immediate"] as? Bool ?? false
                            await activity.end(using: state, dismissalPolicy: immediate ? .immediate : .after(Date().addingTimeInterval(120)))
                            self.orderActivityTokenTasks.removeValue(forKey: activity.id)?.cancel()
                        }
                        result(nil)
                    } else {
                        result(FlutterMethodNotImplemented)
                    }
                } catch {
                    result(FlutterError(code: "activity_unavailable", message: "Unable to update order activity", details: nil))
                }
            }
        }
    }

    @available(iOS 16.1, *)
    private func orderActivitySnapshot(_ activity: Activity<LiveActivitiesAppAttributes>) -> [String: Any] {
        var data: [String: Any] = ["order_id": activity.attributes.orderId, "activity_id": activity.id]
        if let token = activity.pushToken { data["push_token"] = token.map { String(format: "%02x", $0) }.joined() }
        return data
    }

    @available(iOS 16.1, *)
    private func observeOrderActivityToken(_ activity: Activity<LiveActivitiesAppAttributes>) {
        guard orderActivityTokenTasks[activity.id] == nil else { return }
        orderActivityTokenTasks[activity.id] = Task { [weak self] in
            for await token in activity.pushTokenUpdates {
                guard !Task.isCancelled else { return }
                let data: [String: Any] = [
                    "order_id": activity.attributes.orderId, "activity_id": activity.id,
                    "push_token": token.map { String(format: "%02x", $0) }.joined()
                ]
                await MainActor.run { self?.orderActivityChannel?.invokeMethod("token", arguments: data) }
            }
        }
    }

    @available(iOS 16.1, *)
    private func orderActivityState(_ data: [String: Any], previous: LiveActivitiesAppAttributes.ContentState?) -> LiveActivitiesAppAttributes.ContentState {
        let version = Int(String(describing: data["updated_at"] ?? "")) ?? previous?.updatedAt ?? 0
        return LiveActivitiesAppAttributes.ContentState(
            orderId: extractOrderId(from: data) ?? previous?.orderId ?? "",
            orderStatus: toDisplayStatus(extractStatus(from: data) ?? previous?.orderStatus ?? "Preparing"),
            restaurantName: data["restaurant_name"] as? String ?? previous?.restaurantName ?? "Fasakhansta",
            updatedAt: version)
    }

    @available(iOS 16.1, *)
    private func cacheOrderActivity(_ state: LiveActivitiesAppAttributes.ContentState, prefix: String) {
        guard let defaults = UserDefaults(suiteName: liveActivityAppGroupId) else { return }
        for key in ["order_status", "orderStatus"] {
            defaults.set(state.orderStatus, forKey: key)
            defaults.set(state.orderStatus, forKey: "\(prefix)_\(key)")
        }
        defaults.set(state.orderId, forKey: "order_id")
        defaults.set(state.restaurantName, forKey: "restaurant_name")
    }

    private func isLiveActivityPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        let merged = mergedLiveActivityPayload(userInfo)

        let marker = "\(merged["live_activity"] ?? "")".lowercased()
        let type = "\(merged["notification_type"] ?? merged["notificationType"] ?? merged["type"] ?? "")".lowercased()
        let hasStatus = extractStatus(from: merged) != nil
        let hasActivityId = merged["activity-id"] != nil || merged["activity_id"] != nil || merged["activityId"] != nil || merged["live_activity_id"] != nil || merged["liveActivityId"] != nil

        if type == "live_activity" || type == "live-activity" || type == "liveactivity" { return true }
        if marker == "1" || marker == "true" { return true }
        if hasStatus && hasActivityId { return true }
        if hasActivityId { return true }

        return false
    }

    private func mergedLiveActivityPayload(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        var root: [String: Any] = [:]
        for (rawKey, value) in userInfo {
            if let key = rawKey as? String {
                root[key] = value
            }
        }

        let nestedData = parseJsonObject(root["data"]) ?? asDict(root["data"])
        let contentState = parseJsonObject(root["content-state"]) ?? asDict(root["content-state"])
        let aps = asDict(root["aps"])
        let apsContentState = parseJsonObject(aps?["content-state"]) ?? asDict(aps?["content-state"])

        return root
            .merging(nestedData ?? [:]) { _, new in new }
            .merging(contentState ?? [:]) { _, new in new }
            .merging(apsContentState ?? [:]) { _, new in new }
    }

    private func asDict(_ any: Any?) -> [String: Any]? {
        return any as? [String: Any]
    }

    private func parseJsonObject(_ any: Any?) -> [String: Any]? {
        if let dict = any as? [String: Any] {
            return dict
        }
        if let text = any as? String, let data = text.data(using: .utf8) {
            let object = try? JSONSerialization.jsonObject(with: data, options: [])
            return object as? [String: Any]
        }
        return nil
    }

    private func extractStatus(from payload: [String: Any]) -> String? {
        let values: [Any?] = [
            payload["order_status"],
            payload["orderStatus"],
            payload["order_state"],
            payload["orderState"],
            payload["status"],
            (payload["order"] as? [String: Any])?["status"],
        ]

        for value in values {
            guard let value = value else { continue }
            let status = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
            if !status.isEmpty {
                return status
            }
        }
        return nil
    }

    private func extractOrderId(from payload: [String: Any]) -> String? {
        let values: [Any?] = [
            payload["order_id"],
            payload["orderId"],
            payload["id"],
            (payload["order"] as? [String: Any])?["id"],
            (payload["order"] as? [String: Any])?["order_id"],
        ]

        for value in values {
            guard let value = value else { continue }
            let orderId = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
            if !orderId.isEmpty {
                return orderId
            }
        }
        return nil
    }

    private func isTerminalStatus(_ rawStatus: String) -> Bool {
        let normalized = rawStatus
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        return normalized == "ended" ||
            normalized == "delivered" ||
            normalized == "completed" ||
            normalized == "cancelled" ||
            normalized == "declined" || normalized == "canceled" || normalized == "rejected" || normalized == "failed" || normalized == "payment_failed"
    }

    private func toDisplayStatus(_ rawStatus: String) -> String {
        let normalized = rawStatus
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "new_order", "pending", "accepted", "preparing", "in_preparation":
            return "Preparing"
        case "picked_up", "on_the_way", "out_for_delivery", "shipped":
            return "On the Way"
        case "delivered", "completed":
            return "Delivered"
        case "cancelled", "canceled", "declined", "rejected":
            return "Cancelled"
        default:
            let value = rawStatus.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "Preparing" : value
        }
    }
}
