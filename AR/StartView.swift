//
//  StareView.swift
//  AR
//
//  Created by owner on 2025/07/31.
//

import SwiftUI

struct StartView: View {
    @State private var showAR = false

    var body: some View {
        VStack {
            Spacer()

            Text("AR キャラクターを表示する")
                .font(.title)
                .padding()

            Button(action: {
                showAR = true
            }) {
                Text("カメラを起動する")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }

            Spacer()
        }
        .fullScreenCover(isPresented: $showAR) {
            ContentView() // ← あなたのAR表示ビュー
        }
    }
}
