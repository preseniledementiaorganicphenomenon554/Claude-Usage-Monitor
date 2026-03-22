import Foundation

struct UsageData {
    var planType:         String
    var messagesUsed:     Int
    var messagesLimit:    Int
    /// Per-window / session usage (shorter reset cycle, e.g. every 5 h)
    var sessionUsed:      Int    = 0
    var sessionLimit:     Int    = 0
    var resetDate:        Date?
    var rateLimitStatus:  String
    var lastUpdated:      Date

    // MARK: - Computed

    /// True when we have a separate per-window counter
    var hasSessionData: Bool { sessionLimit > 0 }

    /// The "primary" usage to display: session window if available, else billing period
    var primaryUsed:  Int { hasSessionData ? sessionUsed  : messagesUsed }
    var primaryLimit: Int { hasSessionData ? sessionLimit : messagesLimit }

    var usagePercentage: Double {
        guard primaryLimit > 0 else { return 0 }
        return min(1.0, Double(primaryUsed) / Double(primaryLimit))
    }

    var messagesRemaining: Int { max(0, primaryLimit - primaryUsed) }

    var timeUntilReset: String {
        guard let resetDate else { return "Unknown" }
        let secs = resetDate.timeIntervalSince(Date())
        guard secs > 0 else { return "Soon" }
        let h = Int(secs / 3600)
        let m = Int(secs.truncatingRemainder(dividingBy: 3600) / 60)
        if h > 24 { return "\(h/24)d \(h%24)h" }
        if h > 0  { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var lastUpdatedFormatted: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: lastUpdated)
    }

    /// Short label for the menu bar: "45/100"
    var menuBarLabel: String {
        guard primaryLimit > 0 else { return "" }
        return "\(primaryUsed)/\(primaryLimit)"
    }
}
