//
//  OutcomeComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

// MARK: - Stroke Side
enum StrokeSide: String {
    case forehand = "Forehand"
    case backhand = "Backhand"
    
    var displayName: String {
        rawValue
    }
}

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
    let onTap: () -> Void
    let onDrag: (StrokeSide) -> Void
    let isCompact: Bool
    
    @AppStorage("playerHandedness") private var playerHandedness: String = "Right-handed"
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragHandled: Bool = false
    
    // MARK: - Constants
    private struct Layout {
        static let regularSize = (width: CGFloat(200), height: CGFloat(90))
        static let compactAspectRatio: CGFloat = 0.85
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 2
    }
    
    private struct Typography {
        static let emojiSize: CGFloat = 20
        static let textSize: CGFloat = 11
        static let dragHintEmojiSize: CGFloat = 8
        static let dragHintTextSize: CGFloat = 10
    }
    
    private struct Spacing {
        static let vStack: CGFloat = 6
        static let padding: CGFloat = 12
        static let dragHintHStack: CGFloat = 4
        static let dragHintTopPadding: CGFloat = 2
    }
    
    private struct DragConfig {
        static let minimumDistance: CGFloat = 10
        static let threshold: CGFloat = 50
        static let visualFeedbackMultiplier: CGFloat = 0.2
        static let dragOpacity: Double = 0.85
        static let dragScale: CGFloat = 0.97
    }
    
    private struct Animation {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.7
    }
    
    // MARK: - Computed Properties
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    private var isRightHanded: Bool {
        playerHandedness == "Right-handed"
    }
    
    private var buttonSize: (width: CGFloat, height: CGFloat)? {
        isCompact ? nil : Layout.regularSize
    }
    
    private var buttonAspectRatio: CGFloat? {
        isCompact ? Layout.compactAspectRatio : nil
    }
    
    // MARK: - Drag Gesture Helpers
    /// Determines stroke side from drag gesture based on player handedness
    /// Right-handed: drag right = forehand, drag left = backhand
    /// Left-handed: drag right = backhand, drag left = forehand
    private var strokeSideFromDrag: StrokeSide? {
        guard abs(dragOffset.width) > DragConfig.threshold else { return nil }
        
        let isDraggingRight = dragOffset.width > 0
        if isRightHanded {
            return isDraggingRight ? .forehand : .backhand
        } else {
            return isDraggingRight ? .backhand : .forehand
        }
    }
    
    /// Returns arrow direction based on stroke side and player handedness
    /// Right-handed: forehand = right side, backhand = left side
    /// Left-handed: forehand = left side, backhand = right side
    private func arrowDirection(for side: StrokeSide) -> String {
        let isForehand = side == .forehand
        if isRightHanded {
            return isForehand ? "arrow.right" : "arrow.left"
        } else {
            return isForehand ? "arrow.left" : "arrow.right"
        }
    }
    
    var body: some View {
        Button(action: {
            // Only trigger tap if not dragging and drag wasn't handled
            // highPriorityGesture prevents this from firing when drag is detected
            if !isDragging && dragOffset == .zero && !dragHandled {
                onTap()
            }
        }) {
            VStack(spacing: Spacing.vStack) {
                Text(outcome.emoji)
                    .font(.system(size: Typography.emojiSize))
                Text(outcome.displayName(for: selectedLanguage))
                    .font(.system(size: Typography.textSize, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                // Drag hint indicator
                if isDragging, let side = strokeSideFromDrag {
                    dragHintView(for: side)
                }
            }
            .frame(maxWidth: .infinity)
            .modifier(CompactButtonFrameModifier(
                buttonSize: buttonSize,
                aspectRatio: buttonAspectRatio
            ))
            .padding(Spacing.padding)
            .background(
                isSelected 
                    ? Color.accentColor.opacity(0.2) 
                    : outcome.backgroundColor
            )
            .cornerRadius(Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: Layout.borderWidth)
            )
            .offset(x: dragOffset.width * DragConfig.visualFeedbackMultiplier)
            .opacity(isDragging ? DragConfig.dragOpacity : 1.0)
            .scaleEffect(isDragging ? DragConfig.dragScale : 1.0)
        }
        .buttonStyle(.plain)
        .highPriorityGesture(dragGesture)
    }
    
    // MARK: - View Builders
    @ViewBuilder
    private func dragHintView(for side: StrokeSide) -> some View {
        HStack(spacing: Spacing.dragHintHStack) {
            Image(systemName: arrowDirection(for: side))
                .font(.system(size: Typography.dragHintEmojiSize))
            Text(side.displayName)
                .font(.system(size: Typography.dragHintTextSize, weight: .medium))
        }
        .foregroundColor(.accentColor)
        .padding(.top, Spacing.dragHintTopPadding)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: DragConfig.minimumDistance)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragHandled = false
                }
                dragOffset = value.translation
            }
            .onEnded { _ in
                handleDragEnd()
            }
    }
    
    private func handleDragEnd() {
        if let side = strokeSideFromDrag {
            dragHandled = true
            onDrag(side)
        } else {
            dragHandled = false
            onTap()
        }
        
        withAnimation(.spring(
            response: Animation.springResponse,
            dampingFraction: Animation.springDamping
        )) {
            dragOffset = .zero
            isDragging = false
        }
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

// MARK: - Compact Button Frame Modifier
private struct CompactButtonFrameModifier: ViewModifier {
    let buttonSize: (width: CGFloat, height: CGFloat)?
    let aspectRatio: CGFloat?
    
    func body(content: Content) -> some View {
        Group {
            if let size = buttonSize {
                content.frame(width: size.width, height: size.height)
            } else if let ratio = aspectRatio {
                content.aspectRatio(ratio, contentMode: .fit)
            } else {
                content
            }
        }
    }
}

