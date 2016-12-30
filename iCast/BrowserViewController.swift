//
//  ViewController.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/27/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import UIKit

class BrowserViewController: UIViewController, UIWebViewDelegate, UISearchBarDelegate, GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate {


    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet var webView: UIWebView!

    @IBOutlet var activity: UIActivityIndicatorView!

    @IBOutlet var googleCastButton: UIBarButtonItem!

    let browserUtil = BrowserUtil()

    //fileprivate let kReceiverAppID = "AA779DBB"
    fileprivate let kReceiverAppID = kGCKMediaDefaultReceiverApplicationID
    fileprivate let kCancelTitle = "Cancel"
    fileprivate let kDisconnectTitle = "Disconnect"

    fileprivate var deviceScanner:GCKDeviceScanner?
    fileprivate var deviceManager:GCKDeviceManager?
    fileprivate var mediaInformation:GCKMediaInformation?
    fileprivate var selectedDevice:GCKDevice?



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = []

        // [START device-scanner]
        // Establish filter criteria.
        let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID: kReceiverAppID)

        // Initialize device scanner.
        deviceScanner = GCKDeviceScanner(filterCriteria: filterCriteria)
        if let deviceScanner = deviceScanner {
            deviceScanner.add(self)
            deviceScanner.startScan()
            deviceScanner.passiveScan = true
        }
        // [END device-scanner]

        let urlString = "google.com"
        setWebViewProperties()
        setSearchBarProperties()
        let url = BrowserUtil.createURL(string: urlString)
        updateWebView(url: url, urlString: urlString)

    }

    /**
     * Private functions
     */
    private func setSearchBarProperties() {
        searchBar.delegate = self
        searchBar.autocapitalizationType = UITextAutocapitalizationType.none
    }

    private func setWebViewProperties() {
        webView.delegate = self;
        webView.keyboardDisplayRequiresUserAction = true
        webView.frame = self.view.frame;
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackAllowsAirPlay = true
    }

    private func updateWebView(url : URL?, urlString: String?) {
        if let url = url {
            print("Loading \(url.absoluteString)")
            let req = URLRequest(url:url, timeoutInterval: 10)
            searchBar.text = url.absoluteURL.absoluteString
            webView.loadRequest(req)
        } else {
            if var query = urlString {
                query = query.replacingOccurrences(of: " ", with: "+")
                let url = URL(string: "http://www.google.com/search?q=\(query)")
                let request = URLRequest(url: url!, timeoutInterval: 10)
                self.webView.loadRequest(request)
            }
        }
    }

    /**
     * WebView delegate methods
     */
    func webViewDidStartLoad(_ webView : UIWebView) {
        activity.startAnimating()
    }

    func webViewDidFinishLoad(_ webView : UIWebView) {
        activity.stopAnimating()
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let errorString = "The page you wish to view is Invalid"
        webView.loadHTMLString(errorString, baseURL: nil)
    }


    /**
     * SearchBar delegate methods
     */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = searchBar.text
        let url = BrowserUtil.createURL(string: text!)
        updateWebView(url: url, urlString: text)
    }


    func updateCastButtonStates() {
        if (deviceScanner!.devices.count > 0) {
            // Show the Cast button.
            print("Device found!!")
            navigationItem.rightBarButtonItems = [googleCastButton!]
            if (deviceManager != nil && deviceManager?.connectionState == GCKConnectionState.connected) {
                // Show the Cast button in the enabled state.
                googleCastButton!.tintColor = UIColor.blue
            } else {
                // Show the Cast button in the disabled state.
                googleCastButton!.tintColor = UIColor.gray
                print("Setup google cast Gray WTH!!")
            }
        } else{
            // Don't show Cast button.
            navigationItem.rightBarButtonItems = []
        }
    }

    // [START device-scanner-listener]
    // MARK: GCKDeviceScannerListener

    func deviceDidComeOnline(_ device: GCKDevice!) {
        print("Device found: \(device.friendlyName)");
        updateCastButtonStates()
    }

    func deviceDidGoOffline(_ device: GCKDevice!) {
        print("Device went away: \(device.friendlyName)");
        updateCastButtonStates()
    }
    // [END device-scanner-listener]


    func connectToDevice() {
        if (selectedDevice == nil) {
            return
        }
        // [START device-selection]
        let identifier = Bundle.main.bundleIdentifier
        deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
        deviceManager!.delegate = self
        deviceManager!.connect()
        // [END device-selection]
    }

    func deviceDisconnected() {
        selectedDevice = nil
        deviceManager = nil
    }

    func showError(_ error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.description,
                                      preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func castMe(_ sender: Any) {
        if (selectedDevice == nil) {
            let actionSheet = UIAlertController(title: "Connect to Device", message: "Choose the chromecast device to connect", preferredStyle: .actionSheet)


            if let deviceScanner = deviceScanner {
                deviceScanner.passiveScan = false
                for device in deviceScanner.devices  {
                    let castAction = UIAlertAction(title: (device as AnyObject).friendlyName, style: .default) { action -> Void in
                        if (self.selectedDevice == nil) {
                            for device in deviceScanner.devices {
                                if action.title == (device as AnyObject).friendlyName {
                                    self.selectedDevice = device as? GCKDevice
                                    print("Selected device: \(self.selectedDevice!.friendlyName)")
                                    self.connectToDevice()
                                    self.updateCastButtonStates()
                                }
                            }
                        }
                    }
                    actionSheet.addAction(castAction)
                }
                deviceScanner.passiveScan = true
            }

            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheet.addAction(cancelAction)

            //Present the AlertController
            self.present(actionSheet, animated: true, completion: nil)

        } else {
            let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

            let actionSheet = UIAlertController(title: friendlyName, message: nil, preferredStyle: .actionSheet)

            if let info = mediaInformation {
                let mediaAction = UIAlertAction(title: (info.metadata.object(forKey: kGCKMetadataKeyTitle) as! String), style: .default) { action -> Void in
                    //Just dismiss the action sheet
                }
                actionSheet.addAction(mediaAction)
            }

            let disconnectAction = UIAlertAction(title: kDisconnectTitle, style: .default) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheet.addAction(disconnectAction)

            let cancelAction = UIAlertAction(title: kCancelTitle, style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheet.addAction(cancelAction)
            
            //Present the AlertController
            self.present(actionSheet, animated: true, completion: nil)
        }

    }

}
