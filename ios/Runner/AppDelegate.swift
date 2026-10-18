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
private struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public struct ContentState: Codable, Hashable {
        // Keep these fields optional: live_activities 2.x local updates only encode
        // appGroupId, while ActivityKit remote pushes carry the order snapshot.
        var appGroupId: String?
        var order_id: String?
        var order_no: String?
        var order_status: String?
        var status: String?
        var restaurant_name: String?
        var updateId: Double?

        init(appGroupId: String? = nil, order_id: String? = nil,
             order_no: String? = nil, order_status: String? = nil,
             status: String? = nil, restaurant_name: String? = nil,
             updateId: Double? = nil) {
            self.appGroupId = appGroupId
            self.order_id = order_id
            self.order_no = order_no
            self.order_status = order_status
            self.status = status
            self.restaurant_name = restaurant_name
            self.updateId = updateId
        }

        private enum CodingKeys: String, CodingKey {
            case appGroupId, order_id, order_no, order_status, status, restaurant_name, updateId
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            appGroupId = Self.string(values, .appGroupId)
            order_id = Self.string(values, .order_id)
            order_no = Self.string(values, .order_no)
            order_status = Self.string(values, .order_status)
            status = Self.string(values, .status)
            restaurant_name = Self.string(values, .restaurant_name)
            updateId = try values.decodeIfPresent(Double.self, forKey: .updateId)
        }

        private static func string(_ values: KeyedDecodingContainer<CodingKeys>,
                                   _ key: CodingKeys) -> String? {
            if let value = try? values.decode(String.self, forKey: key) { return value }
            if let value = try? values.decode(Int.self, forKey: key) { return String(value) }
            return nil
        }
    }

    var id = UUID()
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let liveActivityAppGroupId = "group.faskhaninja.liveactivities"
    private var liveActivityStateChannel: FlutterMethodChannel?
  
  override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        GMSServices.provideAPIKey("AIzaSyBDfirv6d7BiO-9YnsU5zCHEn9iM9iNtuM")
        GeneratedPluginRegistrant.register(with: self)
        registerLiveActivityStateChannel()
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
            if #available(iOS 16.1, *) {
                Task {
                    _ = await updateLiveActivityFromPush(userInfo)
                    completionHandler([])
                }
            } else {
                completionHandler([])
            }
            return
        }
        completionHandler(.alert) // shows banner even if app is in foreground
    }

    private func registerLiveActivityStateChannel() {
        guard let registrar = self.registrar(forPlugin: "FasakhanstaLiveActivityState") else { return }
        let channel = FlutterMethodChannel(
            name: "fasakhansta/live_activity", binaryMessenger: registrar.messenger()
        )
        liveActivityStateChannel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard call.method == "syncOrderState" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let self = self, let arguments = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            guard #available(iOS 16.1, *) else {
                result(false)
                return
            }
            var userInfo: [AnyHashable: Any] = [:]
            for (key, value) in arguments { userInfo[key] = value }
            Task {
                let didUpdate = await self.updateLiveActivityFromPush(userInfo)
                DispatchQueue.main.async { result(didUpdate) }
            }
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivityFromPush(_ userInfo: [AnyHashable: Any]) async -> Bool {
        let payload = mergedLiveActivityPayload(userInfo)
        guard let rawStatus = extractStatus(from: payload),
              let sharedDefault = UserDefaults(suiteName: liveActivityAppGroupId) else {
            return false
        }

        let orderId = extractOrderId(from: payload)
        let activityId = payloadString(payload, keys: [
            "activity-id", "activity_id", "activityId", "live_activity_id", "liveActivityId"
        ])
        guard orderId != nil || activityId != nil else { return false }

        let displayStatus = toDisplayStatus(rawStatus)
        let incomingUpdateId = updateTimestamp(payload)
        let shouldEnd = isTerminalStatus(rawStatus)
        var didUpdate = false

        for activity in Activity<LiveActivitiesAppAttributes>.activities {
            let prefix = activity.attributes.id.uuidString
            let previous = activity.contentState
            let previousOrderId = previous.order_id ?? defaultsString(sharedDefault,
                keys: ["\(prefix)_order_id", "\(prefix)_orderId"])
            let matchesOrder = orderId != nil && previousOrderId == orderId
            let matchesActivity = activityId == activity.id ||
                activityId?.uppercased() == activity.attributes.id.uuidString

            // Display numbers are never used as database IDs, and a push for a
            // different order must not update or end another active delivery.
            if let orderId = orderId, let previousOrderId = previousOrderId,
               orderId != previousOrderId { continue }
            guard matchesOrder || matchesActivity else { continue }

            let storedUpdateId = timestamp(sharedDefault.object(forKey: "\(prefix)_updateId"))
            let previousUpdateId = [previous.updateId, storedUpdateId].compactMap { $0 }.max()
            let storedStatus = defaultsString(sharedDefault,
                keys: ["\(prefix)_order_status", "\(prefix)_orderStatus"])
            let previousStatus: String
            if let storedUpdateId = storedUpdateId, storedUpdateId > (previous.updateId ?? 0) {
                previousStatus = storedStatus ?? previous.order_status ?? previous.status ?? ""
            } else {
                previousStatus = previous.order_status ?? previous.status ?? storedStatus ?? ""
            }
            if let incoming = incomingUpdateId, let current = previousUpdateId {
                if incoming < current { continue }
                if incoming == current && statusStage(rawStatus) < statusStage(previousStatus) { continue }
            } else if previousUpdateId != nil && statusStage(rawStatus) < statusStage(previousStatus) {
                // Legacy notifications without a server version cannot undo a
                // later state received directly from ActivityKit.
                continue
            }

            let stableOrderId = previousOrderId ?? orderId
            let orderNumber = payloadString(payload, keys: ["order_no", "orderNo", "order_number", "orderNumber"]) ??
                previous.order_no ?? defaultsString(sharedDefault,
                    keys: ["\(prefix)_order_no", "\(prefix)_orderNo"])
            let restaurant = payloadString(payload, keys: ["restaurant_name", "restaurantName"]) ??
                previous.restaurant_name ?? defaultsString(sharedDefault,
                    keys: ["\(prefix)_restaurant_name", "\(prefix)_restaurantName"])
            let contentState = LiveActivitiesAppAttributes.ContentState(
                appGroupId: liveActivityAppGroupId,
                order_id: stableOrderId,
                order_no: orderNumber,
                order_status: displayStatus,
                status: payloadString(payload, keys: ["status"]) ?? rawStatus,
                restaurant_name: restaurant,
                updateId: incomingUpdateId ?? previousUpdateId ?? Date().timeIntervalSince1970
            )
            if let updateId = contentState.updateId {
                sharedDefault.set(updateId, forKey: "\(prefix)_updateId")
            }
            let values: [String: String?] = [
                "order_id": stableOrderId, "orderId": stableOrderId,
                "order_no": orderNumber, "orderNo": orderNumber,
                "order_status": displayStatus, "orderStatus": displayStatus,
                "restaurant_name": restaurant
            ]
            for (key, value) in values {
                if let value = value {
                    sharedDefault.set(value, forKey: "\(prefix)_\(key)")
                    sharedDefault.set(value, forKey: key)
                }
            }

            if shouldEnd {
                await activity.end(using: contentState, dismissalPolicy: .immediate)
            } else {
                await activity.update(using: contentState)
            }
            didUpdate = true
        }
        return didUpdate
    }

    private func updateTimestamp(_ payload: [String: Any]) -> Double? {
        let keys = ["updateId", "status_updated_at", "updated_at", "updatedAt", "timestamp"]
        for source in [payload, asDict(payload["order"]) ?? [:]] {
            for key in keys {
                if let value = timestamp(source[key]) { return value }
            }
        }
        return nil
    }

    private func timestamp(_ value: Any?) -> Double? {
        guard let value = value, !(value is NSNull) else { return nil }
        let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = Double(text), number.isFinite, number > 0 {
            return number > 100_000_000_000 ? number / 1000 : number
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: text) { return date.timeIntervalSince1970 }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: text) { return date.timeIntervalSince1970 }
        let databaseDate = DateFormatter()
        databaseDate.locale = Locale(identifier: "en_US_POSIX")
        databaseDate.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyyy-MM-dd HH:mm:ss.SSSSSS", "yyyy-MM-dd HH:mm:ss"] {
            databaseDate.dateFormat = format
            if let date = databaseDate.date(from: text) { return date.timeIntervalSince1970 }
        }
        return nil
    }

    private func statusStage(_ rawStatus: String) -> Int {
        switch toDisplayStatus(rawStatus) {
        case "Preparing": return 1
        case "On the Way": return 2
        case "Delivered", "Cancelled": return 3
        default: return 0
        }
    }

    private func defaultsString(_ defaults: UserDefaults, keys: [String]) -> String? {
        for key in keys {
            if let value = defaults.object(forKey: key), let text = nonemptyString(value) {
                return text
            }
        }
        return nil
    }

    private func payloadString(_ payload: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = payload[key], let text = nonemptyString(value) { return text }
        }
        return nil
    }

    private func nonemptyString(_ value: Any) -> String? {
        guard !(value is NSNull) else { return nil }
        let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
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
        let order = asDict(payload["order"]) ?? [:]
        let preferredValues: [Any?] = [
            payload["live_activity_status"], payload["liveActivityStatus"],
            payload["tracking_status"], payload["trackingStatus"],
            order["live_activity_status"], order["liveActivityStatus"],
            order["tracking_status"], order["trackingStatus"]
        ]
        for value in preferredValues {
            if let value = value, let status = nonemptyString(value) { return status }
        }
        let values: [Any?] = [
            payload["order_status"], payload["orderStatus"],
            payload["order_state"], payload["orderState"], payload["status"],
            order["status"], order["order_status"], order["orderStatus"],
            order["order_state"], order["orderState"]
        ]
        for value in values {
            guard let value = value, let status = nonemptyString(value) else { continue }
            let courier = payloadString(payload, keys: ["delegate_from_out"]) ??
                payloadString(order, keys: ["delegate_from_out"])
            // Legacy snapshots keep accepted after assigning a branch courier.
            // Only that exact persisted marker changes the customer stage.
            if status.lowercased() == "accepted" && courier == "in_resturant" {
                return "On the Way"
            }
            return status
        }
        return nil
    }

    private func extractOrderId(from payload: [String: Any]) -> String? {
        let values: [Any?] = [
            payload["order_id"],
            payload["orderId"],
            (payload["order"] as? [String: Any])?["id"],
            (payload["order"] as? [String: Any])?["order_id"],
        ]

        for value in values {
            if let value = value, let orderId = nonemptyString(value) { return orderId }
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
            normalized == "canceled" ||
            normalized == "rejected" ||
            normalized == "declined" ||
            normalized == "failed" ||
            normalized == "payment_failed"
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
        case "picked_up", "on_the_way", "out_for_delivery", "shipped", "delivering":
            return "On the Way"
        case "delivered", "completed", "ended":
            return "Delivered"
        case "cancelled", "canceled", "declined", "rejected", "failed", "payment_failed":
            return "Cancelled"
        default:
            let value = rawStatus.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "Preparing" : value
        }
    }
}
