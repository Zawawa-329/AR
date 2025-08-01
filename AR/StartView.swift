//
//  StareView.swift
//  AR
//
//  Created by owner on 2025/07/31.
//

import SwiftUI

struct StartView: View {
    var userName: String
    @State private var showAR = false

    var body: some View {
        VStack(spacing: 40) {
            Text("こんにちは、\(userName) さん")
                .font(.title)
                .padding()

            Button(action: {
                showAR = true
            }) {
                Text("カメラを起動する")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .fullScreenCover(isPresented: $showAR) {
            ContentView() // AR画面
        }
    }
}
