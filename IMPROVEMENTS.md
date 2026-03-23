# Claude Usage Monitor — Roadmap & Improvement Suggestions

> A structured list of recommended improvements for the Claude Usage Monitor macOS app, ordered by priority and impact.

---

## 🔴 High Priority

### 1. Resilience Against claude.ai Page Changes

**Problem:** The entire data pipeline depends on the DOM structure and fetch interceptor of `/settings/usage`. Any update by Anthropic can break parsing and show `0/0`.

**Recommendations:**
- Separate parsing logic into versioned modules (e.g. `ParserV1.swift`, `ParserV2.swift`) with a fallback chain
- Cache the last successful API response in `UserDefaults` — if the current scrape fails, display the last known value with a "stale data" indicator (e.g. a `clock` symbol or grayed-out text)
- Add a `lastSuccessfulScrape` timestamp and surface it in the popover
- Open a GitHub Issue automatically (or show an in-app prompt) when parsing returns `0/0` more than 3 times in a row

**Files to change:** `WebScrapingService.swift`, `UsageData.swift`, `ContentView.swift`

---

### 2. Native macOS Notifications

**Problem:** Users have no way to know they're approaching their limit without manually opening the popover.

**Recommendations:**
- Use `UserNotifications` framework to trigger alerts at configurable thresholds (e.g. 80%, 90%, 100%)
- Add a "Session reset" notification when the 5-hour window resets
- Let users configure which thresholds trigger notifications via a Settings panel

**Implementation sketch:**
```swift
import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            // store granted state
                }
                }

                func sendUsageNotification(used: Int, limit: Int) {
                    let pct = Double(used) / Double(limit)
                        guard pct >= 0.8 else { return }
                            let content = UNMutableNotificationContent()
                                content.title = "Claude Usage Warning"
                                    content.body = "\(used)/\(limit) messages used (\(Int(pct * 100))%)"
                                        content.sound = .default
                                            let request = UNNotificationRequest(identifier: "usage-alert-\(Int(pct*100))", content: content, trigger: nil)
                                                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                                                }
                                                ```

                                                **Files to change:** `AppDelegate.swift`, new `NotificationService.swift`

                                                ---

                                                ### 3. Configurable Refresh Interval

                                                **Problem:** Refresh interval is hardcoded to `120 seconds` in `AppDelegate.swift`. Power users want more frequent updates; casual users may want less battery drain.

                                                **Recommendations:**
                                                - Add a right-click menu on the status bar icon with refresh interval options: 30s / 1min / 2min / 5min / 10min
                                                - Persist the chosen interval in `UserDefaults`
                                                - Show current interval in the popover footer

                                                **Files to change:** `AppDelegate.swift`

                                                ---

                                                ## 🟡 Medium Priority

                                                ### 4. Usage History & Mini Chart

                                                **Problem:** There's no way to see how usage evolved over the current session or billing period.

                                                **Recommendations:**
                                                - Persist usage snapshots (timestamp + used + limit) to a local JSONL file or `UserDefaults` array (keep last 50 entries)
                                                - Render a simple `Charts` (SwiftUI native) line chart in the popover showing usage over time
                                                - Add a "Period total" trend line for billing-period awareness

                                                **Implementation sketch:**
                                                ```swift
                                                import Charts

                                                struct UsagePoint: Identifiable {
                                                    let id = UUID()
                                                        let timestamp: Date
                                                            let used: Int
                                                                let limit: Int
                                                                }

                                                                // In ContentView:
                                                                Chart(historyPoints) { point in
                                                                    LineMark(
                                                                            x: .value("Time", point.timestamp),
                                                                                    y: .value("Used", point.used)
                                                                                        )
                                                                                            .foregroundStyle(.green)
                                                                                            }
                                                                                            .frame(height: 80)
                                                                                            ```

                                                                                            **Files to change:** `UsageData.swift`, `ContentView.swift`, new `HistoryStore.swift`

                                                                                            ---

                                                                                            ### 5. Multi-Account Support

                                                                                            **Problem:** Users with multiple Claude accounts (personal + work) can only monitor one at a time.

                                                                                            **Recommendations:**
                                                                                            - Create separate `WKWebsiteDataStore` instances per account, stored with a user-defined label
                                                                                            - Add an account switcher in the popover or via a right-click menu
                                                                                            - Show the active account name in the popover header

                                                                                            **Notes:** This is the most complex feature on this list. Consider it a v2.0 milestone.

                                                                                            **Files to change:** `WebScrapingService.swift`, `LoginWindowController.swift`, `ContentView.swift`, new `AccountManager.swift`

                                                                                            ---

                                                                                            ### 6. Right-Click Context Menu on Menu Bar Icon

                                                                                            **Problem:** Opening the full popover just to check numbers is heavyweight. Standard macOS convention uses right-click for quick info.

                                                                                            **Recommendations:**
                                                                                            - Right-click shows a compact `NSMenu` with: current usage (e.g. `45 / 100`), percentage, time until reset, and a "Refresh" item
                                                                                            - No popover required for a quick glance

                                                                                            **Implementation sketch:**
                                                                                            ```swift
                                                                                            // In AppDelegate.setupStatusItem():
                                                                                            let menu = NSMenu()
                                                                                            menu.addItem(NSMenuItem(title: "45 / 100 (45%)", action: nil, keyEquivalent: ""))
                                                                                            menu.addItem(NSMenuItem(title: "Resets in 2h 15m", action: nil, keyEquivalent: ""))
                                                                                            menu.addItem(.separator())
                                                                                            menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r"))
                                                                                            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                                                                                            statusItem.menu = menu
                                                                                            ```

                                                                                            **Files to change:** `AppDelegate.swift`

                                                                                            ---

                                                                                            ### 7. Stale Data Indicator

                                                                                            **Problem:** If a refresh fails silently, the user sees old numbers with no warning.

                                                                                            **Recommendations:**
                                                                                            - Track `lastSuccessfulUpdate: Date` in `UsageData`
                                                                                            - If data is older than 10 minutes, show a `⚠️` badge or gray out the menu bar label
                                                                                            - Add a tooltip on the status bar button showing the exact time of last successful refresh

                                                                                            **Files to change:** `AppDelegate.swift`, `UsageData.swift`

                                                                                            ---

                                                                                            ## 🟢 Low Priority (Polish & Distribution)

                                                                                            ### 8. Apple Notarization

                                                                                            **Problem:** The current ad-hoc signing requires users to run `xattr -cr` or right-click → Open on first launch. This is a significant adoption barrier — many users abandon the app at this step.

                                                                                            **Recommendations:**
                                                                                            - Enroll in the Apple Developer Program (~$99/year)
                                                                                            - Notarize the app with `notarytool` as part of the build/release process
                                                                                            - Ship a properly signed DMG — the app will open on first double-click with no friction

                                                                                            **Impact:** This single change could 2–3x the number of successful installs.

                                                                                            ---

                                                                                            ### 9. Official Homebrew Cask

                                                                                            **Problem:** You already have a personal homebrew-tap, but it's not in `homebrew/homebrew-cask` — the main registry that most macOS developers use.

                                                                                            **Recommendations:**
                                                                                            - Once the app is notarized (see #8), submit a PR to [homebrew-core/homebrew-cask](https://github.com/Homebrew/homebrew-cask)
                                                                                            - Users will then be able to install with `brew install --cask claude-usage-monitor`

                                                                                            ---

                                                                                            ### 10. In-App Auto-Update Check

                                                                                            **Problem:** Users have no way of knowing when a new version is released without manually checking GitHub.

                                                                                            **Recommendations:**
                                                                                            - On app launch, make a lightweight request to the GitHub Releases API
                                                                                            - If a newer version is available, show a dismissible banner in the popover: "v1.x available — [View Release]"
                                                                                            - Do NOT auto-download; just surface the link

                                                                                            **Implementation sketch:**
                                                                                            ```swift
                                                                                            func checkForUpdates(currentVersion: String) {
                                                                                                let url = URL(string: "https://api.github.com/repos/theDanButuc/Claude-Usage-Monitor/releases/latest")!
                                                                                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                                                                                            guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                                                                                                          let tag = json["tag_name"] as? String else { return }
                                                                                                                                  let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                                                                                                                                          if latest > currentVersion {
                                                                                                                                                      DispatchQueue.main.async {
                                                                                                                                                                      // Show update banner in ContentView
                                                                                                                                                                                  }
                                                                                                                                                                                          }
                                                                                                                                                                                              }.resume()
                                                                                                                                                                                              }
                                                                                                                                                                                              ```
                                                                                                                                                                                              
                                                                                                                                                                                              **Files to change:** `AppDelegate.swift`, `ContentView.swift`
                                                                                                                                                                                              
                                                                                                                                                                                              ---
                                                                                                                                                                                              
                                                                                                                                                                                              ## Summary Table
                                                                                                                                                                                              
                                                                                                                                                                                              | # | Feature | Priority | Effort | Impact |
                                                                                                                                                                                              |---|---------|----------|--------|--------|
                                                                                                                                                                                              | 1 | Resilient parsing + stale cache | 🔴 High | Medium | High |
                                                                                                                                                                                              | 2 | Native macOS notifications | 🔴 High | Low | High |
                                                                                                                                                                                              | 3 | Configurable refresh interval | 🔴 High | Low | Medium |
                                                                                                                                                                                              | 4 | Usage history & mini chart | 🟡 Medium | Medium | High |
                                                                                                                                                                                              | 5 | Multi-account support | 🟡 Medium | High | Medium |
                                                                                                                                                                                              | 6 | Right-click context menu | 🟡 Medium | Low | Medium |
                                                                                                                                                                                              | 7 | Stale data indicator | 🟡 Medium | Low | Medium |
                                                                                                                                                                                              | 8 | Apple Notarization | 🟢 Low | Low* | Very High |
                                                                                                                                                                                              | 9 | Official Homebrew Cask | 🟢 Low | Low | High |
                                                                                                                                                                                              | 10 | In-app update check | 🟢 Low | Low | Medium |
                                                                                                                                                                                              
                                                                                                                                                                                              > *Low effort once enrolled in Apple Developer Program.
                                                                                                                                                                                              
                                                                                                                                                                                              ---
                                                                                                                                                                                              
                                                                                                                                                                                              ## Recommended Sprint Order
                                                                                                                                                                                              
                                                                                                                                                                                              If starting today, suggested order:
                                                                                                                                                                                              
                                                                                                                                                                                              1. **Notarization** (#8) — removes the biggest adoption blocker
                                                                                                                                                                                              2. **Notifications** (#2) — high-value, ~50 lines of Swift
                                                                                                                                                                                              3. **Stale data indicator** (#7) — quick win, improves trust in the app
                                                                                                                                                                                              4. **Configurable refresh** (#3) — low effort, respects user preferences
                                                                                                                                                                                              5. **Right-click menu** (#6) — standard macOS UX, low effort
                                                                                                                                                                                              6. **Resilient parsing** (#1) — important for long-term stability
                                                                                                                                                                                              7. **Usage history chart** (#4) — differentiates the app from all competitors
                                                                                                                                                                                              8. **Auto-update check** (#10) — keeps users on latest version
                                                                                                                                                                                              9. **Homebrew Cask** (#9) — after notarization, maximizes discoverability
                                                                                                                                                                                              10. **Multi-account** (#5) — v2.0 milestone
                                                                                                                                                                                              
                                                                                                                                                                                              ---
                                                                                                                                                                                              
                                                                                                                                                                                              *Generated based on code analysis of `WebScrapingService.swift`, `AppDelegate.swift`, and competitive research on GitHub (March 2026).*
