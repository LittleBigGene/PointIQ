//
//  SubscriptionService.swift
//  PointIQ
//
//  Created on 12/24/25.
//

import Foundation
import StoreKit
import Combine

enum SubscriptionTier: String {
    case free = "free"
    case premium25 = "premium25"  // $2.99/year for 25 matches
    case premiumUnlimited = "premiumUnlimited"  // $6.99/year for unlimited matches
    
    var matchLimit: Int? {
        switch self {
        case .free:
            return 5
        case .premium25:
            return 25
        case .premiumUnlimited:
            return nil  // Unlimited
        }
    }
}

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    // Product IDs - Replace with your actual product IDs from App Store Connect
    // IMPORTANT: You must create these products in App Store Connect before testing purchases
    // These should be Auto-Renewable Subscriptions with a 1-year period
    // For testing, you can use StoreKit Configuration file or sandbox testing
    private let premium25ProductID = "com.pointiq.premium_history_25"  // $2.99/year for 25 matches
    private let premiumUnlimitedProductID = "com.pointiq.premium_history_unlimited"  // $6.99/year for unlimited matches
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var availableProducts: [Product] = []
    
    // Convenience computed property for backward compatibility
    var isPremium: Bool {
        currentTier != .free
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Check premium status on initialization
        Task { @MainActor in
            await checkPremiumStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePremiumStatus(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Product Loading
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: [premium25ProductID, premiumUnlimitedProductID])
            
            if products.isEmpty {
                // Products not found - likely not configured in App Store Connect yet
                self.errorMessage = "Products not available. Please configure products in App Store Connect or use StoreKit Configuration file for testing."
                self.isLoading = false
                print("⚠️ No products found. Product IDs: \(premium25ProductID), \(premiumUnlimitedProductID)")
            } else {
                // Sort products by price (cheaper first)
                self.availableProducts = products.sorted { product1, product2 in
                    (product1.price as Decimal) < (product2.price as Decimal)
                }
                self.isLoading = false
                print("✅ Loaded \(products.count) products")
            }
        } catch {
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ Error loading products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePremiumStatus(transaction: transaction)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Premium Status Check
    
    @MainActor
    func checkPremiumStatus() async {
        var detectedTier: SubscriptionTier = .free
        
        // Check current entitlements from StoreKit (source of truth)
        // Check for unlimited first (higher tier), then 25 matches
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == premiumUnlimitedProductID {
                    detectedTier = .premiumUnlimited
                    break  // Highest tier, no need to check further
                } else if transaction.productID == premium25ProductID {
                    detectedTier = .premium25
                    // Continue checking in case there's an unlimited subscription
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        // Update UserDefaults cache based on StoreKit status
        UserDefaults.standard.set(detectedTier.rawValue, forKey: "subscriptionTier")
        
        // Also check UserDefaults for manual override (useful for testing/debugging)
        // Note: In production, StoreKit is the source of truth
        if let storedTierString = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let storedTier = SubscriptionTier(rawValue: storedTierString) {
            // Use the higher tier if both exist
            if storedTier == .premiumUnlimited || detectedTier == .premiumUnlimited {
                detectedTier = .premiumUnlimited
            } else if storedTier == .premium25 || detectedTier == .premium25 {
                detectedTier = .premium25
            }
        }
        
        self.currentTier = detectedTier
    }
    
    @MainActor
    private func updatePremiumStatus(transaction: Transaction) async {
        var newTier: SubscriptionTier = .free
        
        if transaction.productID == premiumUnlimitedProductID {
            newTier = .premiumUnlimited
        } else if transaction.productID == premium25ProductID {
            newTier = .premium25
        }
        
        if newTier != .free {
            // Always upgrade to higher tier if user has multiple subscriptions
            if newTier == .premiumUnlimited || self.currentTier == .premiumUnlimited {
                self.currentTier = .premiumUnlimited
            } else {
                self.currentTier = newTier
            }
            // Store in UserDefaults for quick access
            UserDefaults.standard.set(self.currentTier.rawValue, forKey: "subscriptionTier")
        }
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Product Identification
    
    func tierForProduct(_ product: Product) -> SubscriptionTier? {
        if product.id == premium25ProductID {
            return .premium25
        } else if product.id == premiumUnlimitedProductID {
            return .premiumUnlimited
        }
        return nil
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkPremiumStatus()
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}
