import AppKit
import Foundation

public struct BrowserInfo: Identifiable, Hashable {
  public let name: String
  public let bundleID: String
  public let path: URL
  public let icon: NSImage
  public var id: String { bundleID }

  public static func == (lhs: BrowserInfo, rhs: BrowserInfo) -> Bool {
    lhs.bundleID == rhs.bundleID
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bundleID)
  }
}

public func getInstalledBrowsers() -> [BrowserInfo] {
  guard let httpsURL = URL(string: "https://example.com") else { return [] }

  let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: httpsURL)
  var seen = Set<String>()
  var browsers: [BrowserInfo] = []

  for appURL in appURLs {
    guard let bundle = Bundle(url: appURL),
      let bid = bundle.bundleIdentifier
    else { continue }

    let lowered = bid.lowercased()

    // Skip ourselves
    if lowered == bundleIdentifier { continue }

    // Deduplicate
    guard seen.insert(lowered).inserted else { continue }

    let displayName =
      bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
      ?? appURL.deletingPathExtension().lastPathComponent

    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
    icon.size = NSSize(width: 16, height: 16)
    browsers.append(BrowserInfo(name: displayName, bundleID: bid, path: appURL, icon: icon))
  }

  browsers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  return browsers
}
