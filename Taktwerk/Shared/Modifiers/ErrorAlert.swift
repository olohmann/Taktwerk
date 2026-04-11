import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .init(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                if let error {
                    Text(error)
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
