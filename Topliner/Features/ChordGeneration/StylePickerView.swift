import SwiftUI

struct StylePickerView: View {
    let styles: [HarmonicStyle]
    @Binding var selectedStyleID: String

    var body: some View {
        Picker("Style", selection: $selectedStyleID) {
            ForEach(styles, id: \.id) { style in
                Text(style.displayName).tag(style.id)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    @Previewable @State var selectedStyleID = "neo_soul"
    let library = (try? StyleLibrary.defaultLibrary()) ?? StyleLibrary(styles: [])
    StylePickerView(styles: library.styles, selectedStyleID: $selectedStyleID)
        .padding()
}
