import AppKit
import CoreServices
import Foundation

public struct BrowserInfo: Identifiable, Hashable, Sendable {
    public let name: String
    public let bundleID: String
    public let path: URL
    public var id: String { bundleID }
}

public func getInstalledBrowsers() -> [BrowserInfo] {
    guard
        let handlersCF = LSCopyAllHandlersForURLScheme("https" as CFString)?.takeRetainedValue()
            as? [String]
    else {
        return []
    }

    let workspace = NSWorkspace.shared
    var seen = Set<String>()
    var browsers: [BrowserInfo] = []

    for bundleID in handlersCF {
        let lowered = bundleID.lowercased()

        // Skip ourselves
        if lowered == bundleIdentifier {
            continue
        }

        // Deduplicate
        guard seen.insert(lowered).inserted else {
            continue
        }

        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) else {
            continue
        }

        let displayName =
            Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle(url: appURL)?.object(forInfoDictionaryKey: kCFBundleNameKey as String)
                as? String
            ?? appURL.deletingPathExtension().lastPathComponent

        browsers.append(BrowserInfo(name: displayName, bundleID: bundleID, path: appURL))
    }

    browsers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    return browsers
}
