//
//  OutcomeComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

// MARK: - Outcome Button Base
private struct OutcomeButtonBase: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    let style: OutcomeButtonStyle
    
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: style.spacing) {
                Text(outcome.emoji)
                    .font(.system(size: style.emojiSize))
                Text(outcome.displayName(for: selectedLanguage))
                    .font(.system(size: style.textSize, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .modifier(OutcomeButtonFrameModifier(style: style))
            .padding(style.padding)
            .background(
                isSelected 
                    ? Color.accentColor.opacity(0.2) 
                    : outcome.backgroundColor
            )
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: style.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Outcome Button Style
private struct OutcomeButtonStyle {
    let emojiSize: CGFloat
    let textSize: CGFloat
    let spacing: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let minHeight: CGFloat?
    let aspectRatio: CGFloat?
    
    static let postGame = OutcomeButtonStyle(
        emojiSize: 20,
        textSize: 11,
        spacing: 6,
        padding: 12,
        cornerRadius: 10,
        borderWidth: 2,
        minHeight: nil,
        aspectRatio: 0.85
    )
    
    static let inGame = OutcomeButtonStyle(
        emojiSize: 48,
        textSize: 18,
        spacing: 12,
        padding: 20,
        cornerRadius: 16,
        borderWidth: 3,
        minHeight: 120,
        aspectRatio: nil
    )
}

// MARK: - Post-Game Outcome Button
struct PostGameOutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        OutcomeButtonBase(
            outcome: outcome,
            isSelected: isSelected,
            action: action,
            style: .postGame
        )
    }
}

// MARK: - In-Game Outcome Button
struct InGameOutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        OutcomeButtonBase(
            outcome: outcome,
            isSelected: isSelected,
            action: action,
            style: .inGame
        )
    }
}

// MARK: - Outcome Button Frame Modifier
private struct OutcomeButtonFrameModifier: ViewModifier {
    let style: OutcomeButtonStyle
    
    func body(content: Content) -> some View {
        Group {
            if let minHeight = style.minHeight {
                content.frame(minHeight: minHeight)
            } else if let aspectRatio = style.aspectRatio {
                content.aspectRatio(aspectRatio, contentMode: .fit)
            } else {
                content
            }
        }
    }
}

