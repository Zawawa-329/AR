//
//  Sparkle.swift
//  AR
//
//  Created by 小池紗矢 on 2025/08/02.
//

import SwiftUI

struct Sparkle: View {
    var position: CGPoint

    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "sparkles")
            .foregroundColor(.yellow)
            .font(.system(size: 30))
            .position(position)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    self.opacity = 0.0
                    self.scale = 1.5
                }
            }
    }
}
