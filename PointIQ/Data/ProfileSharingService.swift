//
//  ProfileSharingService.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation
import MultipeerConnectivity
import Combine
import CoreBluetooth
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Service for sharing player profile information between nearby devices
/// Only connects when devices are very close (like AirDrop)
class ProfileSharingService: NSObject, ObservableObject {
    static let shared = ProfileSharingService()
    
    private let serviceType = "pointiq-profile"
    private var myPeerID: MCPeerID
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    // Core Bluetooth for proximity detection
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var nearbyPeripherals: [CBPeripheral: Int] = [:] // RSSI values
    private let proximityServiceUUID = CBUUID(string: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
    private let proximityCharacteristicUUID = CBUUID(string: "B9407F31-F5F8-466E-AFF9-25556B57FE6D")
    
    // Proximity threshold: RSSI > -50 dBm means very close (within ~1 meter)
    private let proximityThreshold: Int = -50
    
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredPeers: [MCPeerID] = [] // Peers discovered but not yet connected
    @Published var receivedProfile: PlayerProfile?
    @Published var receivedProfileFromPeer: MCPeerID? // Track which peer sent the profile
    @Published var sharingError: String?
    @Published var isDeviceNearby = false
    @Published var proximityStatus: String = "Move phones closer together"
    
    // AirDrop-style invitation handling
    @Published var pendingInvitation: PendingInvitation?
    
    struct PendingInvitation: Identifiable, Equatable {
        let id = UUID()
        let peerID: MCPeerID
        let invitationHandler: (Bool, MCSession?) -> Void
        
        // Equatable conformance - compare only equatable properties
        // The closure is not compared, which is fine for our use case
        static func == (lhs: PendingInvitation, rhs: PendingInvitation) -> Bool {
            return lhs.id == rhs.id && lhs.peerID == rhs.peerID
        }
    }
    
    private override init() {
        // Create peer ID with device name
        #if canImport(UIKit)
        let deviceName = UIDevice.current.name
        #elseif canImport(AppKit)
        let deviceName = Host.current().name ?? "Device"
        #else
        let deviceName = "Device"
        #endif
        myPeerID = MCPeerID(displayName: deviceName)
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start advertising this device's profile
    func startAdvertising() {
        guard !isAdvertising else { return }
        
        // Start Core Bluetooth for proximity detection
        startProximityDetection()
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        print("📡 Started advertising profile")
    }
    
    /// Stop advertising
    func stopAdvertising() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
        stopProximityDetection()
        isAdvertising = false
        isDeviceNearby = false
        proximityStatus = "Move phones closer together"
        print("📡 Stopped advertising")
    }
    
    /// Start browsing for nearby devices
    func startBrowsing() {
        guard !isBrowsing else { return }
        
        // Start Core Bluetooth for proximity detection
        startProximityDetection()
        
        if session == nil {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
            session?.delegate = self
        }
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
        
        isBrowsing = true
        print("🔍 Started browsing for nearby devices")
    }
    
    /// Stop browsing
    func stopBrowsing() {
        serviceBrowser?.stopBrowsingForPeers()
        serviceBrowser = nil
        stopProximityDetection()
        isBrowsing = false
        isDeviceNearby = false
        proximityStatus = "Move phones closer together"
        print("🔍 Stopped browsing")
    }
    
    /// Send profile to a specific peer
    func sendProfile(_ profile: PlayerProfile, to peerID: MCPeerID) {
        guard let session = session else {
            sharingError = "Session not available"
            return
        }
        
        // If not connected, invite first
        if !session.connectedPeers.contains(peerID) {
            invitePeer(peerID)
            // Wait for connection before sending
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if session.connectedPeers.contains(peerID) {
                    self.sendProfileData(profile, to: peerID)
                } else {
                    self.sharingError = "Failed to connect to \(peerID.displayName)"
                }
            }
        } else {
            sendProfileData(profile, to: peerID)
        }
    }
    
    private func sendProfileData(_ profile: PlayerProfile, to peerID: MCPeerID) {
        guard let session = session else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("✅ Sent profile to \(peerID.displayName)")
        } catch {
            sharingError = "Failed to send profile: \(error.localizedDescription)"
            print("❌ Error sending profile: \(error)")
        }
    }
    
    /// Invite a discovered peer to connect
    func invitePeer(_ peerID: MCPeerID) {
        guard let session = session, let browser = serviceBrowser else { return }
        guard isDeviceNearby else {
            sharingError = "Device is not close enough"
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        print("📤 Invited \(peerID.displayName)")
    }
    
    /// Accept a pending invitation
    func acceptInvitation() {
        guard let invitation = pendingInvitation else { return }
        invitation.invitationHandler(true, session)
        pendingInvitation = nil
        print("✅ Accepted invitation from \(invitation.peerID.displayName)")
    }
    
    /// Reject a pending invitation
    func rejectInvitation() {
        guard let invitation = pendingInvitation else { return }
        invitation.invitationHandler(false, nil)
        pendingInvitation = nil
        print("❌ Rejected invitation from \(invitation.peerID.displayName)")
    }
    
    /// Disconnect from all peers
    func disconnect() {
        session?.disconnect()
        stopAdvertising()
        stopBrowsing()
        connectedPeers = []
        discoveredPeers = []
        receivedProfile = nil
        receivedProfileFromPeer = nil
        pendingInvitation = nil
    }
    
    // MARK: - Proximity Detection
    
    private func startProximityDetection() {
        // Start as central (scanner)
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Start as peripheral (advertiser)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func stopProximityDetection() {
        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        centralManager = nil
        peripheralManager = nil
        nearbyPeripherals.removeAll()
    }
    
    private func updateProximityStatus() {
        let nearbyCount = nearbyPeripherals.values.filter { $0 > proximityThreshold }.count
        isDeviceNearby = nearbyCount > 0
        
        if isDeviceNearby {
            proximityStatus = "✓ Device nearby - ready to share"
        } else {
            proximityStatus = "Move phones closer together"
        }
    }
}

// MARK: - Core Bluetooth Delegates

extension ProfileSharingService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Scan for peripherals advertising our service
            central.scanForPeripherals(withServices: [proximityServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let rssiValue = RSSI.intValue
        nearbyPeripherals[peripheral] = rssiValue
        
        DispatchQueue.main.async {
            self.updateProximityStatus()
        }
        
        // Only allow Multipeer Connectivity when device is very close
        if rssiValue > proximityThreshold {
            print("📶 Device very close: RSSI = \(rssiValue) dBm")
        }
    }
}

extension ProfileSharingService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            // Create and advertise our service
            let service = CBMutableService(type: proximityServiceUUID, primary: true)
            let characteristic = CBMutableCharacteristic(
                type: proximityCharacteristicUUID,
                properties: [.read],
                value: nil,
                permissions: [.readable]
            )
            service.characteristics = [characteristic]
            
            peripheral.add(service)
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [proximityServiceUUID],
                CBAdvertisementDataLocalNameKey: myPeerID.displayName
            ])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error adding service: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate

extension ProfileSharingService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                // Remove from discovered peers when connected
                self.discoveredPeers.removeAll { $0 == peerID }
                print("✅ Connected to \(peerID.displayName)")
            case .connecting:
                print("🔄 Connecting to \(peerID.displayName)...")
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                print("❌ Disconnected from \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            do {
                let decoder = JSONDecoder()
                let profile = try decoder.decode(PlayerProfile.self, from: data)
                self.receivedProfile = profile
                self.receivedProfileFromPeer = peerID
                print("✅ Received profile from \(peerID.displayName)")
            } catch {
                self.sharingError = "Failed to decode profile: \(error.localizedDescription)"
                print("❌ Error decoding profile: \(error)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used for profile sharing
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used for profile sharing
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used for profile sharing
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ProfileSharingService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // AirDrop-style: Show invitation dialog instead of auto-accepting
        guard isDeviceNearby else {
            print("⏸️ Invitation received but device not close enough: \(peerID.displayName)")
            invitationHandler(false, nil)
            return
        }
        
        // Store invitation for user to accept/reject
        DispatchQueue.main.async {
            self.pendingInvitation = PendingInvitation(peerID: peerID, invitationHandler: invitationHandler)
        }
        print("📥 Received invitation from \(peerID.displayName) - waiting for user confirmation")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ProfileSharingService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // AirDrop-style: Show discovered peers, don't auto-invite
        guard isDeviceNearby else {
            print("⏸️ Device found but not close enough: \(peerID.displayName)")
            return
        }
        
        // Add to discovered peers list (user will choose to send)
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) && !self.connectedPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
        print("🔍 Discovered nearby device: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
        print("👋 Lost peer: \(peerID.displayName)")
    }
}

// MARK: - Player Profile Model

struct PlayerProfile: Codable, Equatable {
    let name: String
    let grip: String
    let handedness: String
    let blade: String
    let forehandRubber: String
    let backhandRubber: String
    let eloRating: String
    let homeClub: String
}

