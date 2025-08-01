//
//  AppDelegate.swift
//  AR
//
//  Created by owner on 2025/07/29.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // アプリ全体で使うログイン状態とユーザー名を管理
    @Published var isLoggedIn = false
    @Published var userNameStore = ""

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // State管理用のObservableObjectを作成
        let appState = AppState()

        // RootViewにappStateを環境オブジェクトとして渡す
        let rootView = RootView()
            .environmentObject(appState)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

// ObservableObjectで状態を管理
class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userNameStore = ""
}
