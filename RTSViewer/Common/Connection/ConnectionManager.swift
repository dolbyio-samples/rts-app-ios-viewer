//
//  ConnectionManager.swift
//

import Foundation
import MultipeerConnectivity

class ConnectionManager: NSObject, ObservableObject {
    typealias StreamDetailReceivedHandler = (StreamDetail) -> Void
    private static let serviceType = "stream-share"

    @Published var clients: [MCPeerID]  = []

    private var session: MCSession
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    private var nearbyServiceBrowser: MCNearbyServiceBrowser

    private var streamDetailbeSent: StreamDetail?
    private var peerInvitee: MCPeerID?

    var handler: StreamDetailReceivedHandler?

    var isReceivingStreamDetail: Bool = false {
        didSet {
            if isReceivingStreamDetail {
                nearbyServiceAdvertiser.startAdvertisingPeer()
            } else {
                nearbyServiceAdvertiser.stopAdvertisingPeer()
            }
        }
    }

    init(_ handler: StreamDetailReceivedHandler? = nil) {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ConnectionManager.serviceType)
        nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ConnectionManager.serviceType)
        self.handler = handler
        super.init()
        session.delegate = self
        nearbyServiceBrowser.delegate = self
        nearbyServiceAdvertiser.delegate = self
    }

    func startBrowsing() {
        nearbyServiceBrowser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        nearbyServiceBrowser.stopBrowsingForPeers()
    }

    func invitePeer(_ peerID: MCPeerID, to stream: StreamDetail) {
        streamDetailbeSent = stream
        let context = stream.streamName.data(using: .utf8)
        nearbyServiceBrowser.invitePeer(peerID, to: session, withContext: context, timeout: TimeInterval(30))
    }

    private func send(_ streamDetail: StreamDetail, to peer: MCPeerID) {
        do {
            let data = try JSONEncoder().encode(streamDetail)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let window = UIApplication.shared.currentUIWindow(),
              let context = context,
              let streamName = String(data: context, encoding: .utf8)
        else { return }
        let title = "Accept stream from \(peerID.displayName)"
        let message = "Would you like to accept: \(streamName)?"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            invitationHandler(true, self.session)
        })
        window.rootViewController?.present(alertController, animated: true)
    }
}

extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if clients.contains(peerID) == false {
            clients.append(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = clients.firstIndex(of: peerID) else { return }
        clients.remove(at: index)
    }
}

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let streamDetail = try? JSONDecoder().decode(StreamDetail.self, from: data) else { return }
        DispatchQueue.main.async {
            self.handler?(streamDetail)
        }
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            guard let streamDetailbeSent = streamDetailbeSent else { return }
            send(streamDetailbeSent, to: peerID)
        case .notConnected:
            print("Not connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        @unknown default:
            print("Unknown state: \(state)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}

private extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }

        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }

        return window
    }
}
