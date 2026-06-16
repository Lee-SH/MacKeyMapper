import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            Text("MacKeyMapper")
                .font(.title2).bold()
            Text(state.accessibilityTrusted ? "권한 OK" : "손쉬운 사용 권한 필요")
            Text("모드: \(state.mode == .test ? "테스트" : "리매핑")")
        }
        .padding()
    }
}
