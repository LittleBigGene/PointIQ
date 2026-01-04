//
//  ResizableDivider.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

struct ResizableDivider: View {
    @Binding var heightRatio: Double
    let totalHeight: CGFloat
    let topSectionHeight: CGFloat
    
    @State private var isDragging = false
    @State private var initialRatio: Double = 0.55
    
    private let minRatio: Double = 0.20
    private let maxRatio: Double = 0.70
    
    var body: some View {
        ZStack {
            Divider()
            
            // Drag handle
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDragging ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 60, height: 8)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .background(Color.secondary.opacity(isDragging ? 0.15 : 0.05))
        .contentShape(Rectangle())
        .frame(height: 24)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        initialRatio = heightRatio
                    }
                    
                    // Calculate new ratio based on drag distance
                    let dragDelta = value.translation.height
                    let deltaRatio = dragDelta / totalHeight
                    let newRatio = initialRatio + deltaRatio
                    
                    // Clamp the ratio between min and max
                    let clampedRatio = max(minRatio, min(maxRatio, newRatio))
                    heightRatio = clampedRatio
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

