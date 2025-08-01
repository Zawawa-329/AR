//
//  RootView.swift
//  AR
//
//  Created by 小池紗矢 on 2025/08/01.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn {
                // ログイン済みならStartViewへ
                StartView(userName: appState.userNameStore)
            } else {
                // ログインしていなければLoginViewを表示
                LoginView()
            }
        }
    }
}
