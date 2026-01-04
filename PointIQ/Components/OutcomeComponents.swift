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
    
    @AppStorage("playerHandedness") private var playerHandedness: String = "Right-handed"
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragHandled: Bool = false // Track if drag was handled to prevent double submission
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    private var isRightHanded: Bool {
        playerHandedness == "Right-handed"
    }
    
    private var strokeSideFromDrag: StrokeSide? {
        guard abs(dragOffset.width) > 50 else { return nil } // Minimum drag distance (50pt for intentional gesture)
        if isRightHanded {
            // Right-handed: drag left = backhand, drag right = forehand
            return dragOffset.width < 0 ? .backhand : .forehand
        } else {
            // Left-handed: drag left = forehand, drag right = backhand
            return dragOffset.width < 0 ? .forehand : .backhand
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
            VStack(spacing: 6) {
                Text(outcome.emoji)
                    .font(.system(size: 20))
                Text(outcome.displayName(for: selectedLanguage))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                // Show drag hint when dragging
                if isDragging, let side = strokeSideFromDrag {
                    HStack(spacing: 4) {
                        Image(systemName: dragOffset.width < 0 ? "arrow.left" : "arrow.right")
                            .font(.system(size: 8))
                        if outcome == .badSR {
                            Text("Bad Receive \(side.displayName)")
                                .font(.system(size: 9, weight: .medium))
                        } else {
                            Text(side.displayName)
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
            .aspectRatio(0.6, contentMode: .fit)
            .padding(12)
            .background(
                isSelected 
                    ? Color.accentColor.opacity(0.2) 
                    : outcome.backgroundColor
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .offset(x: dragOffset.width * 0.2) // Visual feedback during drag (reduced multiplier for smoother feel)
            .opacity(isDragging ? 0.85 : 1.0)
            .scaleEffect(isDragging ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragHandled = false // Reset flag when starting new drag
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if let side = strokeSideFromDrag {
                        // Drag completed - submit with stroke side
                        dragHandled = true // Mark as handled to prevent button tap
                        onDrag(side)
                    } else {
                        // Drag was too small - treat as tap (don't mark as handled)
                        dragHandled = false
                        onTap()
                    }
                    // Reset drag state
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                }
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

