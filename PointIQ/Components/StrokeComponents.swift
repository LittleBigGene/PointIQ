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
    
    private static func extractServeInfo(from serve: ServeType?) -> (shortName: String?, emoji: String?) {
        guard let serve = serve else { return (nil, nil) }
        let emoji = serve.emoji.isEmpty ? nil : serve.emoji
        return (serve.shortName, emoji)
    }
    
    init(serve: ServeType?, receive: ReceiveType?, rallies: [RallyType], onRallyTap: ((Int) -> Void)? = nil) {
        let serveInfo = Self.extractServeInfo(from: serve)
        self.serveShortName = serveInfo.shortName
        self.serveEmoji = serveInfo.emoji
        self.receiveEmoji = receive?.emoji
        self.rallyEmojis = rallies.map { $0.emoji }
        self.onRallyTap = onRallyTap
    }
    
    init(point: Point) {
        // Extract serve info
        if let serveTypeString = point.serveType,
           let serveType = ServeType(rawValue: serveTypeString) {
            let serveInfo = Self.extractServeInfo(from: serveType)
            self.serveShortName = serveInfo.shortName
            self.serveEmoji = serveInfo.emoji
        } else {
            self.serveShortName = nil
            self.serveEmoji = nil
        }
        
        // Extract receive info - use actual type if available, otherwise fall back to generic fruit emoji
        if let receiveTypeString = point.receiveType,
           let receiveType = ReceiveType(rawValue: receiveTypeString) {
            self.receiveEmoji = receiveType.emoji
        } else {
            // Fall back to generic fruit emoji for older points without receive type data
            self.receiveEmoji = point.strokeTokens.contains(.fruit) ? StrokeToken.fruit.emoji : nil
        }
        
        // Extract rally info - use actual types if available, otherwise fall back to generic animal emoji
        if !point.rallyTypes.isEmpty {
            self.rallyEmojis = point.rallyTypes.compactMap { rallyTypeString in
                RallyType(rawValue: rallyTypeString)?.emoji
            }
        } else {
            // Fall back to generic animal emoji for older points without rally type data
            let animalTokens = point.strokeTokens.filter { $0 == .animal }
            self.rallyEmojis = Array(repeating: StrokeToken.animal.emoji, count: animalTokens.count)
        }
    }
    
    init(pointData: PointData) {
        // Extract serve info
        if let serveTypeString = pointData.serveType,
           let serveType = ServeType(rawValue: serveTypeString) {
            let serveInfo = Self.extractServeInfo(from: serveType)
            self.serveShortName = serveInfo.shortName
            self.serveEmoji = serveInfo.emoji
        } else {
            self.serveShortName = nil
            self.serveEmoji = nil
        }
        
        // Extract receive info - use actual type if available, otherwise fall back to generic fruit emoji
        if let receiveTypeString = pointData.receiveType,
           let receiveType = ReceiveType(rawValue: receiveTypeString) {
            self.receiveEmoji = receiveType.emoji
        } else {
            // Fall back to generic fruit emoji for older points without receive type data
            let strokeTokens = pointData.strokeTokenValues
            self.receiveEmoji = strokeTokens.contains(.fruit) ? StrokeToken.fruit.emoji : nil
        }
        
        // Extract rally info - use actual types if available, otherwise fall back to generic animal emoji
        if !pointData.rallyTypes.isEmpty {
            self.rallyEmojis = pointData.rallyTypes.compactMap { rallyTypeString in
                RallyType(rawValue: rallyTypeString)?.emoji
            }
        } else {
            // Fall back to generic animal emoji for older points without rally type data
            let strokeTokens = pointData.strokeTokenValues
            let animalTokens = strokeTokens.filter { $0 == .animal }
            self.rallyEmojis = Array(repeating: StrokeToken.animal.emoji, count: animalTokens.count)
        }
    }
    
    // Calculate total emoji count (serve + receive + rallies)
    private var totalEmojiCount: Int {
        var count = 0
        if serveShortName != nil || serveEmoji != nil { count += 1 }
        if receiveEmoji != nil { count += 1 }
        count += rallyEmojis.count
        return count
    }
    
    // Maximum emojis to display before using rolling window
    private let maxDisplayEmojis = 10
    
    // Get full sequence (all emojis)
    private var fullSequence: [(emoji: String, originalRallyIndex: Int?, type: EmojiType)] {
        var sequence: [(emoji: String, originalRallyIndex: Int?, type: EmojiType)] = []
        
        // Build full sequence - include serve even if no emoji (for shortName display)
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
    
    // Get the visible window (for initial display position)
    private var visibleWindowStartIndex: Int {
        let fullCount = fullSequence.count
        if fullCount > maxDisplayEmojis {
            return fullCount - maxDisplayEmojis
        }
        return 0
    }
    
    private enum EmojiType {
        case serve, receive, rally
    }
    
    @State private var isFirstItemVisible: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Show ellipsis only if we're truncating AND first item is not visible
                    if totalEmojiCount > maxDisplayEmojis && visibleWindowStartIndex > 0 && !isFirstItemVisible {
                        Text("…")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .id("ellipsis")
                    }
                    
                    // Display ALL emojis (full sequence) so user can scroll to see everything
                    ForEach(fullSequence.indices, id: \.self) { index in
                        let item = fullSequence[index]
                        let isFirstItem = index == 0
                        
                        Group {
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
                        .background(
                            // Track visibility of first item
                            Group {
                                if isFirstItem {
                                    GeometryReader { geometry in
                                        Color.clear
                                            .preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: geometry.frame(in: .named("scroll")).minX
                                            )
                                    }
                                }
                            }
                        )
                    }
                }
                .frame(minWidth: 0)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // First item is visible if its position is at or before the scroll view's leading edge
                // (with a small threshold for floating point comparison)
                isFirstItemVisible = value <= 20
            }
            .onAppear {
                // Scroll to show the rolling window (last maxDisplayEmojis) by default
                if totalEmojiCount > maxDisplayEmojis && visibleWindowStartIndex > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("item-\(visibleWindowStartIndex)", anchor: .leading)
                        }
                    }
                }
            }
            .onChange(of: totalEmojiCount) { _, _ in
                // When new items are added, scroll to show the latest (rolling window)
                if totalEmojiCount > maxDisplayEmojis && visibleWindowStartIndex > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("item-\(visibleWindowStartIndex)", anchor: .leading)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Serve Type Button
struct ServeTypeButton: View {
    let serveType: ServeType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Text(serveType.shortName)
                .font(.system(size: 20, weight: .bold))
            Text(serveType.displayName)
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
    
    var body: some View {
        VStack(spacing: 6) {
            Text(receiveType.emoji)
                .font(.system(size: 20))
            Text(receiveType.displayName)
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(rallyType.emoji)
                    .font(.system(size: 28))
                Text(rallyType.displayName)
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

// MARK: - Outcome Button
struct OutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(outcome.emoji)
                    .font(.system(size: 20))
                Text(outcome.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
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
        }
        .buttonStyle(.plain)
    }
}


