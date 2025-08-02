//
//  SharedAppData.swift
//  AR
//
//  Created by Kaede on 2025/08/03.
//

// SharedAppData.swift
// AppState.swift (このファイルがプロジェクト内に存在することを確認してください)
// AppState.swift
import Foundation
import Combine

class AppState: ObservableObject {

    static let shared = AppState()

    @Published var showSplash = true
    @Published var isLoggedIn = false
    @Published var userNameStore = ""
    @Published var userResponses: [Int: Int] = [:] // ★追加: userResponsesプロパティ
}
