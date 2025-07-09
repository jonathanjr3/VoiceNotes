//
//  LiveWaveformView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct LiveWaveformView: View {
    let audioLevels: [Float]
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let barWidth = width / CGFloat(audioLevels.count * 2)
            let spacing = barWidth
            
            var path = Path()
            
            for (index, level) in audioLevels.enumerated() {
                let barHeight = max(1, CGFloat(level) * height)
                let x = (CGFloat(index) * (barWidth + spacing)) + (spacing / 2)
                let y = (height - barHeight) / 2
                path.addRect(CGRect(x: x, y: y, width: barWidth, height: barHeight))
            }
            
            context.fill(path, with: .color(color))
        }
    }
}

#Preview {
    LiveWaveformView(audioLevels: (0..<30).map { _ in Float.random(in: 0...1) }, color: .accentColor)
}
