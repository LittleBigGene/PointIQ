//
//  StrokeComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

// MARK: - Scroll Position Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Modifiers

extension View {
    func buttonStyle(isSelected: Bool, cornerRadius: CGFloat = 10) -> some View {
        self
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
    }
}

// MARK: - Double Tap Handler

struct DoubleTapHandler: ViewModifier {
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        tapTask?.cancel()
                        onDoubleTap()
                    }
            )
            .onTapGesture {
                tapTask?.cancel()
                let task = DispatchWorkItem {
                    onSingleTap()
                }
                tapTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
            }
    }
}

extension View {
    func onDoubleTap(singleTap: @escaping () -> Void, doubleTap: @escaping () -> Void) -> some View {
        modifier(DoubleTapHandler(onSingleTap: singleTap, onDoubleTap: doubleTap))
    }
}

// MARK: - Stroke Sequence View
struct StrokeSequenceView: View {
    let serveShortName: String?
    let serveEmoji: String?
    let receiveEmoji: String?
    let rallyEmojis: [String]
    var onRallyTap: ((Int) -> Void)? = nil // Callback when rally emoji is tapped (index parameter)
    var reverseOrder: Bool = false // If true, display sequence from right to left
    var opponentServed: Bool = false // If true, opponent started the sequence with a serve
    
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // MARK: - Initialization Helpers
    
    private static func extractServeInfo(from serve: ServeType?) -> (shortName: String?, emoji: String?) {
        guard let serve = serve else { return (nil, nil) }
        let emoji = serve.emoji.isEmpty ? nil : serve.emoji
        return (serve.shortName, emoji)
    }
    
    private static func extractServeInfo(from serveTypeString: String?) -> (shortName: String?, emoji: String?) {
        guard let serveTypeString = serveTypeString,
              let serveType = ServeType(rawValue: serveTypeString) else {
            return (nil, nil)
        }
        return extractServeInfo(from: serveType)
    }
    
    private static func extractReceiveEmoji(receiveTypeString: String?, strokeTokens: [String]) -> String? {
        // First try to get from receiveType
        if let receiveTypeString = receiveTypeString,
           let receiveType = ReceiveType(rawValue: receiveTypeString) {
            return receiveType.emoji
        }
        // Fallback: check if any stroke token is a fruit name (receive type)
        for token in strokeTokens {
            // Check if token matches a fruit name
            if let receiveType = ReceiveType.allCases.first(where: { $0.fruitName == token }) {
                return receiveType.emoji
            }
            // Also check rawValue for backward compatibility
            if let receiveType = ReceiveType(rawValue: token) {
                return receiveType.emoji
            }
        }
        return nil
    }
    
    private static func extractRallyEmojis(rallyTypes: [String], strokeTokens: [String]) -> [String] {
        // First try to get from rallyTypes array
        if !rallyTypes.isEmpty {
            return rallyTypes.compactMap { RallyType(rawValue: $0)?.emoji }
        }
        // Fallback: extract rally types from strokeTokens (after serve and receive)
        // Serve and receive are typically the first two tokens, rest are rallies
        let rallyTokens = strokeTokens.dropFirst(2) // Skip serve and receive
        return rallyTokens.compactMap { token in
            // Check if token matches an animal name
            if let rallyType = RallyType.allCases.first(where: { $0.animalName == token }) {
                return rallyType.emoji
            }
            // Also check rawValue for backward compatibility
            return RallyType(rawValue: token)?.emoji
        }
    }
    
    // MARK: - Initializers
    
    init(serve: ServeType?, receive: ReceiveType?, rallies: [RallyType], onRallyTap: ((Int) -> Void)? = nil, reverseOrder: Bool = false, opponentServed: Bool = false) {
        let serveInfo = Self.extractServeInfo(from: serve)
        self.serveShortName = serveInfo.shortName
        self.serveEmoji = serveInfo.emoji
        self.receiveEmoji = receive?.emoji
        self.rallyEmojis = rallies.map { $0.emoji }
        self.onRallyTap = onRallyTap
        self.reverseOrder = reverseOrder
        self.opponentServed = opponentServed
    }
    
    init(point: Point, reverseOrder: Bool = false, opponentServed: Bool = false) {
        let serveInfo = Self.extractServeInfo(from: point.serveType)
        self.serveShortName = serveInfo.shortName
        self.serveEmoji = serveInfo.emoji
        self.receiveEmoji = Self.extractReceiveEmoji(
            receiveTypeString: point.receiveType,
            strokeTokens: point.strokeTokens
        )
        self.rallyEmojis = Self.extractRallyEmojis(
            rallyTypes: point.rallyTypes,
            strokeTokens: point.strokeTokens
        )
        self.onRallyTap = nil
        self.reverseOrder = reverseOrder
        self.opponentServed = opponentServed
    }
    
    init(pointData: PointData, reverseOrder: Bool = false, opponentServed: Bool = false) {
        let serveInfo = Self.extractServeInfo(from: pointData.serveType)
        self.serveShortName = serveInfo.shortName
        self.serveEmoji = serveInfo.emoji
        let strokeTokens = pointData.strokeTokenValues
        self.receiveEmoji = Self.extractReceiveEmoji(
            receiveTypeString: pointData.receiveType,
            strokeTokens: strokeTokens
        )
        self.rallyEmojis = Self.extractRallyEmojis(
            rallyTypes: pointData.rallyTypes,
            strokeTokens: strokeTokens
        )
        self.onRallyTap = nil
        self.reverseOrder = reverseOrder
        self.opponentServed = opponentServed
    }
    
    // MARK: - Constants
    
    /// Maximum emojis to display before using rolling window
    private let maxDisplayEmojis = 10
    
    /// Minimum spacer length for reverse order scroll view
    private let reverseOrderSpacerLength: CGFloat = 200
    
    /// Delay before scrolling to position (allows layout to complete)
    private let scrollPositionDelay: TimeInterval = 0.2
    
    /// Threshold for determining if first item is visible (in points)
    private let firstItemVisibilityThreshold: CGFloat = 20
    
    // MARK: - Computed Properties
    
    /// Calculate total emoji count (serve + receive + rallies)
    private var totalEmojiCount: Int {
        var count = 0
        if serveShortName != nil || serveEmoji != nil { count += 1 }
        if receiveEmoji != nil { count += 1 }
        count += rallyEmojis.count
        return count
    }
    
    /// Get full sequence (all emojis) - always in normal order: serve, receive, rallies
    private var fullSequence: [(emoji: String, originalRallyIndex: Int?, type: EmojiType)] {
        var sequence: [(emoji: String, originalRallyIndex: Int?, type: EmojiType)] = []
        
        // Build full sequence - always in serve, receive, rallies order
        if serveShortName != nil || serveEmoji != nil {
            sequence.append((serveEmoji ?? "", nil, .serve))
        }
        if let receiveEmoji = receiveEmoji {
            sequence.append((receiveEmoji, nil, .receive))
        }
        for (index, emoji) in rallyEmojis.enumerated() {
            sequence.append((emoji, index, .rally))
        }
        
        return sequence
    }
    
    /// Get the visible window start index for rolling window display
    private var visibleWindowStartIndex: Int {
        let fullCount = fullSequence.count
        if fullCount > maxDisplayEmojis {
            return fullCount - maxDisplayEmojis
        }
        return 0
    }
    
    /// Get the scroll target index for initial positioning
    private var scrollTargetIndex: Int {
        visibleWindowStartIndex
    }
    
    /// Indices to iterate - reversed when reverseOrder is true
    private var displayIndices: [Int] {
        reverseOrder ? fullSequence.indices.reversed() : Array(fullSequence.indices)
    }
    
    // MARK: - State
    
    @State private var isFirstItemVisible: Bool = false
    
    // MARK: - Supporting Types
    
    private enum EmojiType {
        case serve, receive, rally
    }
    
    // MARK: - Helper Methods
    
    /// Checks if an index is the first item in display order
    /// - When reversed: first displayed item is the last in sequence (serve)
    /// - When not reversed: first displayed item is the first in sequence (serve)
    private func isFirstItem(_ index: Int) -> Bool {
        if reverseOrder {
            // When reversed, first item displayed is the last in sequence
            return index == fullSequence.count - 1
        } else {
            // When not reversed, first item is index 0
            return index == 0
        }
    }
    
    private func oppTagText(for language: Language) -> String {
        switch language {
        case .english: return "Opp"
        case .japanese: return "相手"
        case .chinese: return "對手"
        }
    }
    
    /// Creates an emoji view for a sequence item
    @ViewBuilder
    private func emojiView(for item: (emoji: String, originalRallyIndex: Int?, type: EmojiType), at index: Int) -> some View {
        HStack(spacing: 4) {
            // Show "Opp" tag for serve type when opponent served
            if item.type == .serve && opponentServed {
                Text(oppTagText(for: selectedLanguage))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            }
            
            // Show serve shortName for serve type
            if item.type == .serve, let serveShortName = serveShortName {
                Text(serveShortName)
                    .font(.system(size: 14, weight: .bold))
            }
            
            // Show the emoji (only if not empty)
            if !item.emoji.isEmpty {
                Text(item.emoji)
                    .font(.system(size: 18))
                    .onTapGesture {
                        // Only handle tap for rally emojis
                        if let rallyIndex = item.originalRallyIndex {
                            onRallyTap?(rallyIndex)
                        }
                    }
            }
        }
        .id("item-\(index)")
        .background(visibilityTracker(for: index))
    }
    
    /// Creates a visibility tracker for the first item
    @ViewBuilder
    private func visibilityTracker(for index: Int) -> some View {
        if isFirstItem(index) {
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minX
                    )
            }
        }
    }
    
    // MARK: - Scroll Positioning
    
    /// Scrolls to the appropriate position based on reverse order
    private func scrollToPosition(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + scrollPositionDelay) {
            withAnimation {
                if reverseOrder {
                    scrollToReverseOrderPosition(proxy: proxy)
                } else {
                    scrollToNormalOrderPosition(proxy: proxy)
                }
            }
        }
    }
    
    /// Scrolls to position when in reverse order (right-to-left display)
    private func scrollToReverseOrderPosition(proxy: ScrollViewProxy) {
        guard !fullSequence.isEmpty else { return }
        
        // When reversed, display order (left to right): rallies..., receive, serve
        // We want serve and receive visible on the right
        let serveIndex = fullSequence.count - 1
        proxy.scrollTo("item-\(serveIndex)", anchor: .trailing)
    }
    
    /// Scrolls to position when in normal order (left-to-right display)
    private func scrollToNormalOrderPosition(proxy: ScrollViewProxy) {
        // When not reversed, scroll to show rolling window from left
        guard totalEmojiCount > maxDisplayEmojis && visibleWindowStartIndex > 0 else { return }
        proxy.scrollTo("item-\(scrollTargetIndex)", anchor: .leading)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            scrollContent
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    isFirstItemVisible = value <= firstItemVisibilityThreshold
                }
                .onAppear {
                    scrollToPosition(proxy: proxy)
                }
                .onChange(of: totalEmojiCount) { _, _ in
                    scrollToPosition(proxy: proxy)
                }
                .onChange(of: reverseOrder) { _, _ in
                    scrollToPosition(proxy: proxy)
                }
        }
    }
    
    private var scrollContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if reverseOrder {
                    // Right-to-left: Display order: [rallies...] [receive] [serve] (right to left)
                    // Spacer at end makes scroll view wider, allowing us to scroll to show rightmost items
                    emojiSequenceView
                    ellipsisView
                    Spacer(minLength: reverseOrderSpacerLength)
                } else {
                    // Left-to-right: normal order
                    ellipsisView
                    emojiSequenceView
                }
            }
            .frame(minWidth: 0)
        }
    }
    
    @ViewBuilder
    private var ellipsisView: some View {
        if totalEmojiCount > maxDisplayEmojis && visibleWindowStartIndex > 0 && !isFirstItemVisible {
            Text("…")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .id("ellipsis")
        }
    }
    
    private var emojiSequenceView: some View {
        ForEach(displayIndices, id: \.self) { index in
            let item = fullSequence[index]
            emojiView(for: item, at: index)
        }
    }
}

// MARK: - Serve Type Button
struct ServeTypeButton: View {
    let serveType: ServeType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(serveType.shortName)
                .font(.system(size: 20, weight: .bold))
            Text(serveType.displayName(for: selectedLanguage))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(isSelected: isSelected)
        .onDoubleTap(singleTap: onTap, doubleTap: onDoubleTap)
    }
}

// MARK: - Receive Type Button
struct ReceiveTypeButton: View {
    let receiveType: ReceiveType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(receiveType.emoji)
                .font(.system(size: 20))
            Text(receiveType.displayName(for: selectedLanguage))
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(isSelected: isSelected)
        .onDoubleTap(singleTap: onTap, doubleTap: onDoubleTap)
    }
}

// MARK: - Rally Type Button
struct RallyTypeButton: View {
    let rallyType: RallyType
    let isSelected: Bool
    let action: () -> Void
    
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(rallyType.emoji)
                    .font(.system(size: 28))
                Text(rallyType.displayName(for: selectedLanguage))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(16)
            .buttonStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

