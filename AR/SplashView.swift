//
//  SplashView.swift
//  AR
//
//  Created by 小池紗矢 on 2025/08/01.
//

import SwiftUI



struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.98, blue: 0.91).ignoresSafeArea()

            VStack {
                Spacer()

                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .opacity(isActive ? 1 : 0)
                                    .scaleEffect(isActive ? 1 : 0.8)
                                    .animation(.easeIn(duration: 1.2), value: isActive)

                                Spacer()
            }
        }
        .onAppear {
            isActive = true
            // 2秒後にログイン画面へ遷移
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    AppState.shared.showSplash = false
                }
            }
        }
    }
}
