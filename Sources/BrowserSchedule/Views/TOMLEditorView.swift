import AppKit
import SwiftUI

struct TOMLEditorView: NSViewRepresentable {
  @Binding var text: String

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSTextView.scrollableTextView()
    guard let textView = scrollView.documentView as? NSTextView else {
      return scrollView
    }

    textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.isAutomaticSpellingCorrectionEnabled = false
    textView.isAutomaticLinkDetectionEnabled = false
    textView.isRichText = false
    textView.usesFindPanel = true
    textView.allowsUndo = true
    textView.isEditable = true
    textView.isSelectable = true
    textView.textContainerInset = NSSize(width: 6, height: 6)
    textView.backgroundColor = NSColor(
      red: 0x22 / 255.0, green: 0x2B / 255.0, blue: 0x2D / 255.0, alpha: 1)
    textView.insertionPointColor = NSColor(
      red: 0xFC / 255.0, green: 0xFC / 255.0, blue: 0xFA / 255.0, alpha: 1)
    textView.selectedTextAttributes = [
      .backgroundColor: NSColor(
        red: 0x3D / 255.0, green: 0x44 / 255.0, blue: 0x46 / 255.0, alpha: 1),
      .foregroundColor: NSColor(
        red: 0xD8 / 255.0, green: 0xD8 / 255.0, blue: 0xD0 / 255.0, alpha: 1),
    ]
    textView.delegate = context.coordinator

    textView.string = text
    context.coordinator.applyHighlighting(to: textView)

    scrollView.backgroundColor = NSColor(
      red: 0x22 / 255.0, green: 0x2B / 255.0, blue: 0x2D / 255.0, alpha: 1)
    scrollView.drawsBackground = true

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else { return }
    if textView.string != text {
      let ranges = textView.selectedRanges
      textView.string = text
      textView.selectedRanges = ranges
      context.coordinator.applyHighlighting(to: textView)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  class Coordinator: NSObject, NSTextViewDelegate {
    var parent: TOMLEditorView

    init(parent: TOMLEditorView) {
      self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      parent.text = textView.string
      applyHighlighting(to: textView)
    }

    @MainActor func applyHighlighting(to textView: NSTextView) {
      guard let storage = textView.textStorage else { return }
      let text = textView.string
      let fullRange = NSRange(location: 0, length: (text as NSString).length)
      guard fullRange.length > 0 else { return }

      let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
      let boldFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)

      storage.beginEditing()

      // Reset to defaults
      storage.addAttribute(
        .foregroundColor,
        value: NSColor(red: 0xD8 / 255.0, green: 0xD8 / 255.0, blue: 0xD0 / 255.0, alpha: 1),
        range: fullRange)
      storage.addAttribute(.font, value: baseFont, range: fullRange)

      // Keys: identifier before = (at start of line)
      applyPattern(
        "^\\s*[A-Za-z_][A-Za-z0-9_]*(?=\\s*=)", to: storage, in: text,
        color: NSColor(red: 0xFF / 255.0, green: 0x61 / 255.0, blue: 0x88 / 255.0, alpha: 1),
        options: .anchorsMatchLines)

      // Strings: "..."
      applyPattern(
        "\"[^\"\\n]*\"", to: storage, in: text,
        color: NSColor(red: 0xE7 / 255.0, green: 0xDB / 255.0, blue: 0x75 / 255.0, alpha: 1))

      // Section headers: [section] or [section.subsection]
      applyPattern(
        "^\\s*\\[.+?\\]\\s*$", to: storage, in: text,
        color: NSColor(red: 0x5A / 255.0, green: 0xD4 / 255.0, blue: 0xE6 / 255.0, alpha: 1),
        font: boldFont, options: .anchorsMatchLines)

      // Booleans
      applyPattern(
        "\\b(true|false)\\b", to: storage, in: text,
        color: NSColor(red: 0xFC / 255.0, green: 0x98 / 255.0, blue: 0x67 / 255.0, alpha: 1))

      // Numbers (standalone after =)
      applyPattern(
        "(?<==\\s*)\\d+(?:\\.\\d+)?", to: storage, in: text,
        color: NSColor(red: 0xAB / 255.0, green: 0x9D / 255.0, blue: 0xF2 / 255.0, alpha: 1))

      // Comments last — overrides everything (correct for full-line and trailing comments)
      applyPattern(
        "#.*$", to: storage, in: text,
        color: NSColor(red: 0x72 / 255.0, green: 0x70 / 255.0, blue: 0x72 / 255.0, alpha: 1),
        options: .anchorsMatchLines)

      storage.endEditing()
    }

    private func applyPattern(
      _ pattern: String,
      to storage: NSTextStorage,
      in text: String,
      color: NSColor,
      font: NSFont? = nil,
      options: NSRegularExpression.Options = []
    ) {
      guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return
      }
      let fullRange = NSRange(location: 0, length: (text as NSString).length)
      for match in regex.matches(in: text, range: fullRange) {
        storage.addAttribute(.foregroundColor, value: color, range: match.range)
        if let font {
          storage.addAttribute(.font, value: font, range: match.range)
        }
      }
    }
  }
}
