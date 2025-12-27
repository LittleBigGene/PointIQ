//
//  ConfirmationOverlay.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

struct ConfirmationOverlay: View {
    let emoji: String
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 80))
            .transition(.scale.combined(with: .opacity))
    }
}

