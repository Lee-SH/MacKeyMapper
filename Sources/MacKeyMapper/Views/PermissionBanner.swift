import SwiftUI

struct PermissionBanner: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("키 입력 감지에는 '손쉬운 사용' 권한이 필요합니다. 허용 후 앱을 다시 실행하세요.")
                .font(.callout)
            Spacer()
            Button("설정 열기") { Permissions.promptAndOpenSettings() }
            Button("다시 확인") { state.refreshPermission() }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
