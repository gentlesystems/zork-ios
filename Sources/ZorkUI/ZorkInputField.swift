import SwiftUI
import UIKit

/// A UITextField wrapper that fires `onSubmit` when the user presses Return
/// without resigning first responder — keeps the keyboard visible between commands.
struct ZorkInputField: UIViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool
    var isEnabled: Bool
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        tf.textColor = .green
        tf.tintColor = .green
        tf.backgroundColor = .clear
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.returnKeyType = .send
        tf.keyboardAppearance = .dark
        tf.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        return tf
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        let width = proposal.width ?? 0
        let intrinsicHeight = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
        return CGSize(width: width, height: intrinsicHeight)
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        // Only push text outward; don't clobber what the user is typing
        if tf.text != text { tf.text = text }
        tf.isEnabled = isEnabled

        if isFocused && !tf.isFirstResponder {
            DispatchQueue.main.async { tf.becomeFirstResponder() }
        } else if !isFocused && tf.isFirstResponder {
            DispatchQueue.main.async { tf.resignFirstResponder() }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ZorkInputField

        init(parent: ZorkInputField) { self.parent = parent }

        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            // Return false → UITextField keeps first responder → keyboard stays up
            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }
    }
}
