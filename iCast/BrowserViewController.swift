//
//  ViewController.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/27/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import UIKit
import AVFoundation

class BrowserViewController: UIViewController {


    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet var webView: UIWebView!

    @IBOutlet var activity: UIActivityIndicatorView!

    @IBOutlet var googleCastButton: UIBarButtonItem!

    @IBOutlet var play: UIBarButtonItem!

    let browserUtil = BrowserUtil()

    //fileprivate let kReceiverAppID = "AA779DBB"
    fileprivate let kReceiverAppID = kGCKMediaDefaultReceiverApplicationID
    fileprivate let kCancelTitle = "Cancel"
    fileprivate let kDisconnectTitle = "Disconnect"
    private lazy var btnImage:UIImage = {
        return UIImage(named: "icon-cast-identified.png")!
    }()
    private lazy var btnImageselected:UIImage = {
        return UIImage(named: "icon-cast-connected.png")!
    }()

    fileprivate var deviceScanner:GCKDeviceScanner?
    fileprivate var deviceManager:GCKDeviceManager?
    fileprivate var selectedDevice:GCKDevice?
    fileprivate var mediaInformation: GCKMediaInformation?
    fileprivate var mediaControlChannel: GCKMediaControlChannel?
    fileprivate var applicationMetadata: GCKApplicationMetadata?

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

        let urlString = "https://einthusan.tv/movie/watch/544d/?lang=tamil"
        setWebViewProperties()
        setSearchBarProperties()
        let url = BrowserUtil.createURL(string: urlString)
        updateWebView(url: url, urlString: urlString)

        NotificationCenter.default.addObserver(self, selector:#selector(playerItemBecameCurrentNotification(notification:)), name: NSNotification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: nil)
    }

    func playerItemBecameCurrentNotification(notification: Notification) {
        print("playerItemBecameCurrentNotification=\(notification)")
        if let playerItem = notification.object as? AVPlayerItem {

            let asset = playerItem.asset as? AVURLAsset
            print ("Asset is \(asset)")
            let url = asset?.url
            let path = url?.absoluteString
            print("Path: \(path!)")
            //if let path = path, // Show alert if not connected.
            //(deviceManager?.connectionState == GCKConnectionState.connected)  {

            if let path = path {
                //Cleanup Existing state
                if(mediaInformation != nil) {
                    navigationItem.rightBarButtonItems?.removeLast()
                }

                let metadata = GCKMediaMetadata()
                metadata?.setString("iCasting Now", forKey: kGCKMetadataKeyTitle)
                metadata?.setString(path,
                                    forKey:kGCKMetadataKeySubtitle)

                let url = URL(string:"https://commondatastorage.googleapis.com/gtv-videos-bucket/" +
                    "sample/images/BigBuckBunny.jpg")
                metadata?.addImage(GCKImage(url: url, width: 480, height: 360))
                var contentType: String?
                getContentType(urlPath: path) { (type) in
                    contentType = type
                    print("ContentType is \(contentType)")
                }

                if (contentType ?? "").isEmpty {
                    print("String is nil or empty")
                    contentType = "application/x-mpegurl"
                }
                contentType = "application/x-mpegurl"
                mediaInformation = GCKMediaInformation(
                    contentID: path,
                    streamType: GCKMediaStreamType.buffered,
                    contentType: contentType,
                    metadata: metadata,
                    streamDuration: 0,
                    mediaTracks: [],
                    textTrackStyle: nil,
                    customData: nil
                )
                navigationItem.rightBarButtonItems?.append(play)
            }
        }
    }

    func getContentType(urlPath: String, completion: @escaping (_ type: String)->(Void)) {
        if let url = URL(string: urlPath) {
            var request = URLRequest(url: url)
            request.httpShouldHandleCookies = true
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
                if let httpResponse = response as? HTTPURLResponse, error == nil {
                    print("Response is \(httpResponse)")
                    if let ct = httpResponse.allHeaderFields["Content-Type"] as? String {
                        completion(ct)
                    }
                }
            }
            task.resume()
        }
    }


    @IBAction func play(_ sender: UIBarButtonItem) {
        print("Cast Video")

        // Show alert if not connected.
        if (deviceManager?.connectionState != GCKConnectionState.connected) {
            let alert = UIAlertController(title: "Not Connected",
                                          message: "Please connect to Cast device",
                                          preferredStyle: UIAlertControllerStyle.alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        if let mediaInformation = mediaInformation {

            // Cast the media
            let requestId = mediaControlChannel!.loadMedia(mediaInformation, autoplay: true)
            if (requestId == kGCKInvalidRequestID) {
                mediaControlChannel!.stop()
            }
        }
        // [END load-media]
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

            let cancelAction  = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheet.addAction(cancelAction)

            //Present the AlertController
            self.present(actionSheet, animated: true, completion: nil)

        } else {
            updateStatsFromDevice()
            let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

            let actionSheet = UIAlertController(title: friendlyName, message: nil, preferredStyle: .actionSheet)

            if let info = mediaInformation {
                let mediaAction = UIAlertAction(title: (info.metadata.object(forKey: kGCKMetadataKeyTitle) as! String), style: .default) { action -> Void in
                    //Just dismiss the action sheet
                }
                actionSheet.addAction(mediaAction)
            }

            let disconnectAction = UIAlertAction(title: kDisconnectTitle, style: .default) { action -> Void in
                print("Disconnecting Device device: \(self.selectedDevice!.friendlyName)")
                // Disconnect button.
                self.deviceManager?.leaveApplication()
                self.deviceManager?.disconnect()
                self.deviceDisconnected();
                self.updateCastButtonStates();
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

/**
 * Private functions
 */
extension BrowserViewController {


    fileprivate func setSearchBarProperties() {
        searchBar.delegate = self
        searchBar.autocapitalizationType = UITextAutocapitalizationType.none
    }

    fileprivate func setWebViewProperties() {
        webView.delegate = self;
        webView.keyboardDisplayRequiresUserAction = true
        webView.frame = self.view.frame;
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackAllowsAirPlay = true
    }

    fileprivate func updateWebView(url : URL?, urlString: String?) {
        if let url = url {
            let req = URLRequest(url:url, timeoutInterval: 10)
            searchBar.text = url.absoluteURL.absoluteString
            webView.loadRequest(req)
            webView.stringByEvaluatingJavaScript(from: "window.alert=null;")
        } else {
            if var query = urlString {
                query = query.replacingOccurrences(of: " ", with: "+")
                let url = URL(string: "http://www.google.com/search?q=\(query)")
                let request = URLRequest(url: url!, timeoutInterval: 10)
                self.webView.loadRequest(request)
            }
        }
    }

    fileprivate func updateCastButtonStates() {
        if (deviceScanner!.devices.count > 0) {
            // Show the Cast button.
            navigationItem.rightBarButtonItems = [googleCastButton!]
            if (deviceManager != nil && deviceManager?.connectionState == GCKConnectionState.connected) {
                googleCastButton!.tintColor = UIColor.blue
            } else {
                // Show the Cast button in the disabled state.
                googleCastButton!.tintColor = UIColor.gray
            }
        } else{
            // Don't show Cast button.
            navigationItem.rightBarButtonItems = []
        }
    }


    fileprivate func connectToDevice() {
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

    fileprivate func deviceDisconnected() {
        selectedDevice = nil
        deviceManager = nil
    }

    fileprivate func updateStatsFromDevice() {
        if deviceManager?.connectionState == GCKConnectionState.connected
            && mediaControlChannel?.mediaStatus != nil {
            mediaInformation = mediaControlChannel?.mediaStatus.mediaInformation
        }
    }


}

extension BrowserViewController : GCKDeviceManagerDelegate {

    func deviceManagerDidConnect(_ deviceManager: GCKDeviceManager!) {
        print("Connected.");
        updateCastButtonStates();
        deviceManager.launchApplication(kReceiverAppID);
    }
    // [END launch-application]

    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didConnectToCastApplication
        applicationMetadata: GCKApplicationMetadata!,
                       sessionID: String!,
                       launchedApplication: Bool) {
        print("Application has launched.");
        self.mediaControlChannel = GCKMediaControlChannel()
        mediaControlChannel!.delegate = self
        deviceManager.add(mediaControlChannel)
        mediaControlChannel!.requestStatus()
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didFailToConnectToApplicationWithError error: Error!) {
        print("Received notification that device failed to connect to application.");
        showError(error);
        deviceDisconnected();
        updateCastButtonStates();
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didFailToConnectWithError error: Error!) {
        print("Received notification that device failed to connect.");

        showError(error);
        deviceDisconnected();
        updateCastButtonStates();
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didDisconnectWithError error: Error!) {
        print("Received notification that device disconnected.");

        if (error != nil) {
            showError(error)
        }
        deviceDisconnected();
        updateCastButtonStates();
    }



    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didReceive metadata: GCKApplicationMetadata!) {
        applicationMetadata = metadata
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription,
                                      preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension BrowserViewController :  GCKMediaControlChannelDelegate {

    func mediaControlChannel(_ mediaControlChannel: GCKMediaControlChannel!, didFailToLoadMediaWithError error: Error!) {
            print("Failed to load media with Error: \(error)")
    }

    func mediaControlChannel(_ mediaControlChannel: GCKMediaControlChannel!, requestDidFailWithID requestID: Int, error: Error!) {
        print("Failed to load media of request: \(requestID) with Error: \(error)")
    }
}

extension BrowserViewController : GCKDeviceScannerListener {

    func deviceDidComeOnline(_ device: GCKDevice!) {
        print("Device found: \(device.friendlyName)");
        updateCastButtonStates()
    }

    func deviceDidGoOffline(_ device: GCKDevice!) {
        print("Device went away: \(device.friendlyName)");
        updateCastButtonStates()
    }
}

extension BrowserViewController : UIWebViewDelegate {

    func webViewDidStartLoad(_ webView : UIWebView) {
        activity.startAnimating()
    }

    func webViewDidFinishLoad(_ webView : UIWebView) {
        activity.stopAnimating()
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {

        if (error._code == 204 && error._domain == "WebKitErrorDomain") {
            // "Plug-in handled load" (i.e. audio/video file)
        } else if (error._code != NSURLErrorCancelled) {
            webView.loadHTMLString(error.localizedDescription, baseURL: nil)
        }
    }
    
}

extension BrowserViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = searchBar.text
        let url = BrowserUtil.createURL(string: text!)
        updateWebView(url: url, urlString: text)
    }
}
