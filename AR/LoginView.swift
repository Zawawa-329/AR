//
//  LoginView.swift
//  AR
//
//  Created by 小池紗矢 on 2025/08/01.
//
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputName: String = ""

    var body: some View {
        VStack(spacing: 30) {
            Text("ようこそ")
                .font(.largeTitle)
                .padding()

            TextField("名前を入力してください", text: $inputName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                if !inputName.isEmpty {
                    appState.userNameStore = inputName
                    appState.isLoggedIn = true
                }
            }) {
                Text("ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(inputName.isEmpty)

            Spacer()
        }
    }
}

