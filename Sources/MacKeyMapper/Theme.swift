import SwiftUI

/// 키보드/창의 색 구성. UI 전용 개념이라 앱 타깃에 둔다.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let windowBackground: Color
    let keyboardBackground: Color
    let keyCapBackground: Color
    let keyCapPressed: Color
    let keyCapMapped: Color
    let keyBorder: Color
    let pendingBorder: Color
    let labelColor: Color
    let nameColor: Color
    let accent: Color   // 리매핑 배지(→대상) 색
    let colorScheme: ColorScheme   // 시스템 컨트롤(피커/메뉴/목록)이 따라갈 외관

    static let all: [Theme] = [dark, light, ocean, sunset]

    static func by(id: String?) -> Theme {
        all.first { $0.id == id } ?? dark
    }

    static let dark = Theme(
        id: "dark", name: "다크",
        windowBackground: Color(white: 0.12),
        keyboardBackground: Color(white: 0.16),
        keyCapBackground: Color(white: 0.24),
        keyCapPressed: Color(red: 0.25, green: 0.55, blue: 1.0),
        keyCapMapped: Color.blue.opacity(0.30),
        keyBorder: Color(white: 0.40),
        pendingBorder: .orange,
        labelColor: .white,
        nameColor: Color(white: 0.65),
        accent: Color(red: 0.45, green: 0.7, blue: 1.0),
        colorScheme: .dark
    )

    static let light = Theme(
        id: "light", name: "라이트",
        windowBackground: Color(white: 0.95),
        keyboardBackground: Color(white: 0.84),
        keyCapBackground: .white,
        keyCapPressed: Color(red: 0.30, green: 0.55, blue: 0.95),
        keyCapMapped: Color.blue.opacity(0.15),
        keyBorder: Color(white: 0.70),
        pendingBorder: .orange,
        labelColor: .black,
        nameColor: Color(white: 0.40),
        accent: Color(red: 0.15, green: 0.4, blue: 0.85),
        colorScheme: .light
    )

    static let ocean = Theme(
        id: "ocean", name: "오션",
        windowBackground: Color(red: 0.05, green: 0.10, blue: 0.20),
        keyboardBackground: Color(red: 0.08, green: 0.15, blue: 0.28),
        keyCapBackground: Color(red: 0.12, green: 0.22, blue: 0.40),
        keyCapPressed: Color(red: 0.20, green: 0.65, blue: 0.95),
        keyCapMapped: Color(red: 0.20, green: 0.55, blue: 0.85).opacity(0.45),
        keyBorder: Color(red: 0.25, green: 0.42, blue: 0.62),
        pendingBorder: .yellow,
        labelColor: .white,
        nameColor: Color(red: 0.62, green: 0.78, blue: 0.92),
        accent: Color(red: 0.5, green: 0.85, blue: 1.0),
        colorScheme: .dark
    )

    static let sunset = Theme(
        id: "sunset", name: "선셋",
        windowBackground: Color(red: 0.15, green: 0.08, blue: 0.10),
        keyboardBackground: Color(red: 0.22, green: 0.12, blue: 0.14),
        keyCapBackground: Color(red: 0.33, green: 0.18, blue: 0.20),
        keyCapPressed: Color(red: 0.97, green: 0.55, blue: 0.35),
        keyCapMapped: Color(red: 0.90, green: 0.45, blue: 0.35).opacity(0.45),
        keyBorder: Color(red: 0.52, green: 0.32, blue: 0.32),
        pendingBorder: .yellow,
        labelColor: Color(red: 1.0, green: 0.96, blue: 0.92),
        nameColor: Color(red: 0.85, green: 0.72, blue: 0.64),
        accent: Color(red: 1.0, green: 0.7, blue: 0.5),
        colorScheme: .dark
    )
}
