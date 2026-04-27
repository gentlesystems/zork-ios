import SwiftUI
import UIKit

/// A read-only, selectable, auto-scrolling text view for terminal output.
/// When `adaptive` is true the font shrinks so the engine's 60+ column lines
/// fit the available width. When false the font follows the system's Dynamic
/// Type body size so iOS-level "Larger Text" settings take effect.
struct TerminalTextView: UIViewRepresentable {

    let text: String
    var adaptive: Bool = true

    func makeUIView(context: Context) -> AutoFitMonospaceTextView {
        let tv = AutoFitMonospaceTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .black
        tv.textColor = .green
        tv.isScrollEnabled = true
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        // Prevent the text view from shrinking the scroll area
        tv.contentInsetAdjustmentBehavior = .automatic
        tv.adaptive = adaptive
        return tv
    }

    func updateUIView(_ tv: AutoFitMonospaceTextView, context: Context) {
        if tv.adaptive != adaptive { tv.adaptive = adaptive }
        guard tv.text != text else { return }
        tv.text = text
        // Scroll to bottom after the layout pass
        DispatchQueue.main.async {
            let end = NSRange(location: tv.text.utf16.count, length: 0)
            tv.scrollRangeToVisible(end)
        }
    }
}

/// UITextView that picks a monospaced font size on every layout so that
/// `targetColumns` characters fit the current width. Floors at `minPointSize`
/// to keep text readable on very narrow screens, caps at `maxPointSize` so
/// iPad/landscape doesn't blow the text up.
final class AutoFitMonospaceTextView: UITextView {

    var targetColumns: CGFloat = 70
    var minPointSize:  CGFloat = 8
    var maxPointSize:  CGFloat = 24

    /// When false, the view uses a Dynamic Type-scaled monospace body font and
    /// skips the autofit math entirely.
    var adaptive: Bool = true {
        didSet {
            guard adaptive != oldValue else { return }
            if adaptive {
                adjustsFontForContentSizeCategory = false
                setNeedsLayout()      // re-applies an autofit size
            } else {
                applySystemMonospaceFont()
            }
        }
    }

    /// Per-point advance width of the system monospace font (computed once).
    private static let perPointAdvance: CGFloat = {
        let probe = UIFont.monospacedSystemFont(ofSize: 100, weight: .regular)
        return "M".size(withAttributes: [.font: probe]).width / 100
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        guard adaptive else { return }

        let usableWidth = bounds.width - textContainerInset.left - textContainerInset.right
        guard usableWidth > 0 else { return }

        let ideal   = usableWidth / (targetColumns * Self.perPointAdvance)
        let clamped = (ideal * 2).rounded(.down) / 2 // 0.5pt steps for stability
        let size    = max(minPointSize, min(maxPointSize, clamped))

        if let current = font, abs(current.pointSize - size) < 0.25 { return }
        font = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Anchor at 17pt (default body size) and let UIFontMetrics rescale per
    /// the user's Dynamic Type setting in iOS Settings → Display & Brightness.
    private func applySystemMonospaceFont() {
        let base    = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        let metrics = UIFontMetrics(forTextStyle: .body)
        font = metrics.scaledFont(for: base)
        adjustsFontForContentSizeCategory = true
    }
}
