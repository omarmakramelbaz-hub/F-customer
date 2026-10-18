import ActivityKit
import WidgetKit
import SwiftUI
import UIKit


extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex & 0xFF0000) >> 16) / 255,
            green: Double((hex & 0x00FF00) >> 8) / 255,
            blue: Double(hex & 0x0000FF) / 255
        )
    }
}

let brandColor = Color(hex: 0xFD7201)
let surfaceStart = Color(hex: 0x111111)
let surfaceEnd = Color(hex: 0x1C1C1C)

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

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


let sharedDefault = UserDefaults(suiteName: "group.faskhaninja.liveactivities")!


func firstString(for keys: [String], defaultValue: String = "") -> String {
    for key in keys {
        if let value = sharedDefault.object(forKey: key) {
            let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                return text
            }
        }
    }
    return defaultValue
}

func scopedKeys(prefix: String?, keys: [String]) -> [String] {
    guard let prefix = prefix, !prefix.isEmpty else { return keys }
    return keys.map { "\(prefix)_\($0)" }
}

func fallbackOrderId(from prefix: String?) -> String {
    guard let prefix = prefix, !prefix.isEmpty else { return "--" }
    if prefix.hasPrefix("order_") {
        let value = String(prefix.dropFirst("order_".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            return value
        }
    }
    return "--"
}

func normalizedStatus(_ raw: String) -> String {
    raw
        .lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "-", with: "_")
        .replacingOccurrences(of: " ", with: "_")
}

func displayStatus(_ raw: String) -> String {
    switch normalizedStatus(raw) {
    case "new_order", "pending", "accepted", "preparing", "in_preparation":
        return "Preparing"
    case "picked_up", "on_the_way", "out_for_delivery", "shipped", "delivering":
        return "On the Way"
    case "delivered", "completed", "ended":
        return "Delivered"
    case "cancelled", "canceled", "declined", "rejected", "failed", "payment_failed":
        return "Cancelled"
    default:
        return raw.isEmpty ? "Preparing" : raw
    }
}

struct DeliveryLiveData: Hashable {
    let orderStatus: String
    let restaurantName: String
    let orderId: String
    let orderNumber: String

    var progress: Double {
        switch normalizedStatus(orderStatus) {
        case "preparing", "pending", "new_order", "accepted", "in_preparation":
            return 0.30
        case "picked_up", "on_the_way", "out_for_delivery", "shipped", "delivering":
            return 0.72
        case "delivered", "completed", "ended":
            return 1.0
        case "cancelled", "canceled", "declined", "rejected", "failed", "payment_failed":
            return 0.0
        default:
            return 0.20
        }
    }

    var statusSymbol: String {
        switch normalizedStatus(orderStatus) {
        case "preparing", "pending", "new_order", "accepted", "in_preparation":
            return "fork.knife.circle.fill"
        case "picked_up", "on_the_way", "out_for_delivery", "shipped", "delivering":
            return "scooter"
        case "delivered", "completed", "ended":
            return "checkmark.seal.fill"
        case "cancelled", "canceled", "declined", "rejected", "failed", "payment_failed":
            return "xmark.seal.fill"
        default:
            return "shippingbox.fill"
        }
    }

    var shortStatus: String {
        switch normalizedStatus(orderStatus) {
        case "preparing", "pending", "new_order", "accepted", "in_preparation":
            return "Prep"
        case "picked_up", "on_the_way", "out_for_delivery", "shipped", "delivering":
            return "On Way"
        case "delivered", "completed", "ended":
            return "Done"
        case "cancelled", "canceled", "declined", "rejected", "failed", "payment_failed":
            return "Cancelled"
        default:
            return orderStatus
        }
    }
}

func deliveryData(prefix: String? = nil,
                  state: LiveActivitiesAppAttributes.ContentState? = nil) -> DeliveryLiveData {
    // Remote ActivityKit updates do not launch the app or write App Group
    // defaults. Read their content-state before the local plugin fallback.
    let status = displayStatus(state?.order_status ?? state?.status ?? firstString(
        for: scopedKeys(prefix: prefix, keys: ["order_status", "orderStatus", "status"]),
        defaultValue: "Preparing"
    ))
    let restaurant = state?.restaurant_name ?? firstString(
        for: scopedKeys(prefix: prefix, keys: ["restaurant_name", "restaurantName", "restaurant"]),
        defaultValue: "Fasakhansta"
    )
    let orderId = state?.order_id ?? firstString(
        for: scopedKeys(prefix: prefix, keys: ["order_id", "orderId"]),
        defaultValue: fallbackOrderId(from: prefix)
    )
    let orderNumber = state?.order_no ?? firstString(
        for: scopedKeys(prefix: prefix, keys: ["order_no", "orderNo", "order_number", "orderNumber"]),
        defaultValue: orderId
    )

    return DeliveryLiveData(
        orderStatus: status,
        restaurantName: restaurant,
        orderId: orderId,
        orderNumber: orderNumber
    )
}

struct StatusPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(brandColor.opacity(0.95))
            )
    }
}

struct AppLogoView: View {
    let size: CGFloat

    init(size: CGFloat = 18) {
        self.size = size
    }

    var body: some View {
        Image("app_logo")
            .resizable()
            .renderingMode(.original)
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }
}

struct IslandPanel<Content: View>: View {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let content: Content

    init(
        horizontalPadding: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

struct DeliveryStatusView: View {
    let data: DeliveryLiveData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [surfaceStart, surfaceEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image("app_logo")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.restaurantName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("Order #\(data.orderNumber)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.70))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                    StatusPill(title: data.orderStatus)
                }

                ProgressView(value: data.progress)
                    .tint(brandColor)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                HStack(spacing: 10) {
                    Label {
                        Text(data.orderStatus)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: data.statusSymbol)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))

                    Spacer()

                    Text("Order #\(data.orderNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
struct DeliveryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let data = deliveryData(prefix: "\(context.attributes.id)", state: context.state)

            DeliveryStatusView(data: data)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let data = deliveryData(prefix: "\(context.attributes.id)", state: context.state)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandPanel {
                        HStack(spacing: 6) {
                            AppLogoView(size: 18)
                            Image(systemName: data.statusSymbol)
                                .foregroundColor(brandColor)
                                .font(.system(size: 14, weight: .bold))
                            Text(data.shortStatus)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    IslandPanel(horizontalPadding: 9, verticalPadding: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .foregroundColor(brandColor)
                            Text(data.orderNumber)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    IslandPanel(horizontalPadding: 12, verticalPadding: 7) {
                        VStack(spacing: 2) {
                            Text(data.restaurantName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("Order #\(data.orderNumber)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    IslandPanel(horizontalPadding: 12, verticalPadding: 10) {
                        VStack(spacing: 8) {
                            ProgressView(value: data.progress)
                                .tint(brandColor)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Capsule())

                            HStack(spacing: 6) {
                                Image(systemName: data.statusSymbol)
                                Text(data.orderStatus)
                                    .lineLimit(1)
                                Spacer()
                                Text("Order #\(data.orderNumber)")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                        }
                    }
                }
            } compactLeading: {
                AppLogoView(size: 16)
                    .padding(.leading, 1)
            } compactTrailing: {
                Text(data.orderStatus)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.trailing, 1)
            } minimal: {
                AppLogoView(size: 14)
            }
        }
    }
}

struct DeliveryEntry: TimelineEntry {
    let date: Date
    let data: DeliveryLiveData
}

struct DeliveryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeliveryEntry {
        DeliveryEntry(date: Date(), data: deliveryData())
    }

    func getSnapshot(in context: Context, completion: @escaping (DeliveryEntry) -> Void) {
        completion(DeliveryEntry(date: Date(), data: deliveryData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeliveryEntry>) -> Void) {
        let entry = DeliveryEntry(date: Date(), data: deliveryData())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct DeliveryHomeScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "DeliveryHomeScreenWidget",
            provider: DeliveryTimelineProvider()
        ) { entry in
            DeliveryStatusView(data: entry.data)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Delivery Status")
        .description("Track your order")
    }
}


@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            DeliveryActivityWidget()
        }
        DeliveryHomeScreenWidget()
    }
}
