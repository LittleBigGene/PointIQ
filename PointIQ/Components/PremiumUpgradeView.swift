//
//  PremiumUpgradeView.swift
//  PointIQ
//
//  Created on 12/24/25.
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @ObservedObject var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("legendLanguage") private var selectedLanguageRaw: String = Language.english.rawValue
    @State private var selectedProduct: Product?
    
    private var selectedLanguage: Language {
        Language(rawValue: selectedLanguageRaw) ?? .english
    }
    
    // Separate products by tier
    private var premium25Product: Product? {
        subscriptionService.availableProducts.first { product in
            subscriptionService.tierForProduct(product) == .premium25
        }
    }
    
    private var premiumUnlimitedProduct: Product? {
        subscriptionService.availableProducts.first { product in
            subscriptionService.tierForProduct(product) == .premiumUnlimited
        }
    }
    
    // MARK: - Translation Helpers
    
    private func upgradeTitleText(for language: Language) -> String {
        switch language {
        case .english: return "Choose Your Plan"
        case .japanese: return "プランを選択"
        case .chinese: return "選擇您的方案"
        }
    }
    
    private func upgradeDescriptionText(for language: Language) -> String {
        switch language {
        case .english: return "Select a subscription plan to unlock more match history. Annual subscriptions."
        case .japanese: return "より多くの試合履歴を解除するには、サブスクリプションプランを選択してください。年間サブスクリプション。"
        case .chinese: return "選擇訂閱方案以解鎖更多比賽歷史記錄。年度訂閱。"
        }
    }
    
    private func featuresTitleText(for language: Language) -> String {
        switch language {
        case .english: return "What's Included:"
        case .japanese: return "含まれるもの："
        case .chinese: return "包含內容："
        }
    }
    
    private func premium25HistoryText(for language: Language) -> String {
        switch language {
        case .english: return "Up to 25 matches"
        case .japanese: return "最大25試合"
        case .chinese: return "最多25場比賽"
        }
    }
    
    private func premiumUnlimitedHistoryText(for language: Language) -> String {
        switch language {
        case .english: return "Unlimited matches"
        case .japanese: return "無制限の試合"
        case .chinese: return "無限比賽"
        }
    }
    
    private func selectPlanText(for language: Language) -> String {
        switch language {
        case .english: return "Select Plan"
        case .japanese: return "プランを選択"
        case .chinese: return "選擇方案"
        }
    }
    
    private func advancedStatsText(for language: Language) -> String {
        switch language {
        case .english: return "Advanced statistics and analytics"
        case .japanese: return "高度な統計と分析"
        case .chinese: return "進階統計與分析"
        }
    }
    
    private func purchaseButtonText(for language: Language) -> String {
        switch language {
        case .english: return "Purchase"
        case .japanese: return "購入"
        case .chinese: return "購買"
        }
    }
    
    private func restoreButtonText(for language: Language) -> String {
        switch language {
        case .english: return "Restore Purchases"
        case .japanese: return "購入を復元"
        case .chinese: return "恢復購買"
        }
    }
    
    private func cancelButtonText(for language: Language) -> String {
        switch language {
        case .english: return "Cancel"
        case .japanese: return "キャンセル"
        case .chinese: return "取消"
        }
    }
    
    private func loadingText(for language: Language) -> String {
        switch language {
        case .english: return "Loading..."
        case .japanese: return "読み込み中..."
        case .chinese: return "載入中..."
        }
    }
    
    private func errorText(for language: Language) -> String {
        switch language {
        case .english: return "Error"
        case .japanese: return "エラー"
        case .chinese: return "錯誤"
        }
    }
    
    private func yearlySubscriptionText(for language: Language) -> String {
        switch language {
        case .english: return "per year"
        case .japanese: return "年ごと"
        case .chinese: return "每年"
        }
    }
    
    private func earlySupporterPricingText(for language: Language) -> String {
        switch language {
        case .english: return "Early Supporter Pricing"
        case .japanese: return "早期サポーター価格"
        case .chinese: return "早期支持者價格"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text(upgradeTitleText(for: selectedLanguage))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(upgradeDescriptionText(for: selectedLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Subscription Tiers
                    VStack(spacing: 16) {
                        // Premium 50 Matches Tier
                        if let product50 = premium25Product {
                            SubscriptionTierCard(
                                product: product50,
                                title: premium25HistoryText(for: selectedLanguage),
                                features: [
                                    advancedStatsText(for: selectedLanguage)
                                ],
                                isSelected: selectedProduct?.id == product50.id,
                                isEarlySupporter: true,
                                selectedLanguage: selectedLanguage,
                                onSelect: {
                                    selectedProduct = product50
                                }
                            )
                        }
                        
                        // Premium Unlimited Tier
                        if let productUnlimited = premiumUnlimitedProduct {
                            SubscriptionTierCard(
                                product: productUnlimited,
                                title: premiumUnlimitedHistoryText(for: selectedLanguage),
                                features: [
                                    advancedStatsText(for: selectedLanguage)
                                ],
                                isSelected: selectedProduct?.id == productUnlimited.id,
                                isEarlySupporter: true,
                                selectedLanguage: selectedLanguage,
                                onSelect: {
                                    selectedProduct = productUnlimited
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    if subscriptionService.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Loading products...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if subscriptionService.availableProducts.isEmpty {
                        VStack(spacing: 12) {
                            if let errorMessage = subscriptionService.errorMessage {
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            } else {
                                Text("No products available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                            Text("Products need to be configured in App Store Connect or use StoreKit Configuration file for testing.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else if selectedProduct == nil {
                        VStack(spacing: 8) {
                            Text("Please select a plan above")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button(action: {
                                // Auto-select first product if user clicks
                                if let firstProduct = subscriptionService.availableProducts.first {
                                    selectedProduct = firstProduct
                                }
                            }) {
                                Text(selectPlanText(for: selectedLanguage))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await purchaseProduct()
                            }
                        }) {
                            Text(purchaseButtonText(for: selectedLanguage))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Restore Button
                    Button(action: {
                        Task {
                            await subscriptionService.restorePurchases()
                        }
                    }) {
                        Text(restoreButtonText(for: selectedLanguage))
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.bottom)
                    
                    // Error Message
                    if let errorMessage = subscriptionService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(cancelButtonText(for: selectedLanguage)) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await subscriptionService.loadProducts()
            // Auto-select the first available product
            await MainActor.run {
                if selectedProduct == nil, let firstProduct = subscriptionService.availableProducts.first {
                    selectedProduct = firstProduct
                }
            }
        }
        .onChange(of: subscriptionService.availableProducts) { _, products in
            // Auto-select first product when products load
            Task { @MainActor in
                if selectedProduct == nil, let firstProduct = products.first {
                    selectedProduct = firstProduct
                }
            }
        }
    }
    
    private func purchaseProduct() async {
        guard let product = selectedProduct else {
            await MainActor.run {
                subscriptionService.errorMessage = "Please select a plan first"
            }
            return
        }
        
        await MainActor.run {
            subscriptionService.errorMessage = nil
            subscriptionService.isLoading = true
        }
        
        do {
            let transaction = try await subscriptionService.purchase(product)
            await MainActor.run {
                subscriptionService.isLoading = false
                if transaction != nil {
                    // Purchase successful, check if premium status updated
                    Task {
                        await subscriptionService.checkPremiumStatus()
                        if subscriptionService.isPremium {
                            dismiss()
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                subscriptionService.isLoading = false
                subscriptionService.errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
        }
    }
}

struct SubscriptionTierCard: View {
    let product: Product
    let title: String
    let features: [String]
    let isSelected: Bool
    let isEarlySupporter: Bool
    let selectedLanguage: Language
    let onSelect: () -> Void
    
    private func yearlySubscriptionText(for language: Language) -> String {
        switch language {
        case .english: return "per year"
        case .japanese: return "年ごと"
        case .chinese: return "每年"
        }
    }
    
    private func earlySupporterPricingText(for language: Language) -> String {
        switch language {
        case .english: return "Early Supporter Pricing"
        case .japanese: return "早期サポーター価格"
        case .chinese: return "早期支持者價格"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if isEarlySupporter {
                            Text(earlySupporterPricingText(for: selectedLanguage))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(product.displayPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let subscription = product.subscription {
                                Text(subscription.subscriptionPeriod.displayName(for: selectedLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(yearlySubscriptionText(for: selectedLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Product.SubscriptionPeriod {
    func displayName(for language: Language) -> String {
        let unit: String
        switch self.unit {
        case .day:
            unit = language == .english ? "day" : (language == .japanese ? "日" : "天")
        case .week:
            unit = language == .english ? "week" : (language == .japanese ? "週" : "週")
        case .month:
            unit = language == .english ? "month" : (language == .japanese ? "ヶ月" : "個月")
        case .year:
            unit = language == .english ? "year" : (language == .japanese ? "年" : "年")
        @unknown default:
            unit = ""
        }
        
        // For yearly subscriptions, show "per year" format
        if self.unit == .year && value == 1 {
            return language == .english ? "per year" : (language == .japanese ? "年ごと" : "每年")
        } else if value == 1 {
            return language == .english ? "per \(unit)" : (language == .japanese ? "\(unit)ごと" : "每\(unit)")
        } else {
            return language == .english ? "every \(value) \(unit)s" : (language == .japanese ? "\(value)\(unit)ごと" : "每\(value)\(unit)")
        }
    }
}
