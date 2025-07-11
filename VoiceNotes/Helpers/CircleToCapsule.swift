//
//  CircleToCapsule.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 11/07/2025.
//


import SwiftUI

struct CircleToCapsule: Shape {
    var animatableParameter: Double

    var animatableData: Double {
        get { animatableParameter }
        set { animatableParameter = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // When animatableParameter is 1.0, cornerRadius is rect.width / 2, making it a circle.
        // When animatableParameter is 0.0, cornerRadius is a smaller value, making it a capsule.
        let cornerRadius = (rect.width / 4) + (animatableParameter * (rect.width / 4))
        
        return Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}
