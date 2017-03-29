//
//  ViewController.swift
//  TextPeer
//
//  Created by smbss on 18/03/2017.
//  Copyright © 2017 smbss. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var connectToPeersButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    let serviceType = "text-peer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        textField.delegate = self
    }

    @IBAction func connectToPeersPressed(_ sender: UIButton) {
        showConnectionPrompt()
    }
    
    @IBAction func sendMessagePressed(_ sender: UIButton) {
        guard textField.text == nil else {
            sendMessage(message: textField.text!)
            return
        }
    }
    
    func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        print("Started hosting")
    }
    
    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: serviceType, session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        print("MCBrowser presented")
    }
    
    func startHosting() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        print("Started hosting")
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: serviceType, session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        print("MCBrowser presented")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Started receiving stream with name \(streamName) from \(peerID.displayName). Stream: \(stream)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource with name \(resourceName) from \(peerID.displayName). Progress: \(progress)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("Finished receiving resource with name \(resourceName) from \(peerID.displayName). LocalURL: \(localURL). Error \(String(describing: error))")
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        print("Host was selected")
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        print("MCBrowser was cancelled")
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let msg = String(data: data, encoding: String.Encoding.utf8) {
                self.messageLabel.text = msg
            } else {
                print("Error converting message data to text")
            }
        }
    }
    
    func sendMessage(message: String) {
        if mcSession.connectedPeers.count > 0 {
            if let stringToData = message.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                do {
                    try mcSession.send(stringToData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            } else {
                print("Error converting message text to data")
            }
        } else {
            print("No peers connected: \(mcSession.connectedPeers.count)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
