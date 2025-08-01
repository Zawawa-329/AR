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
            if appState.showSplash {
                SplashView()
                    .onAppear {
                        // 2秒後にスプラッシュを非表示に
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                appState.showSplash = false
                            }
                        }
                    }
            } else if appState.isLoggedIn {
                StartView(userName: appState.userNameStore)
            } else {
                LoginView()
            }
        }
    }
}
