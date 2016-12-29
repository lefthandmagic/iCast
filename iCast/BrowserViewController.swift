//
//  ViewController.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/27/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import UIKit

class BrowserViewController: UIViewController, UIWebViewDelegate, UISearchBarDelegate {


    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet var webView: UIWebView!

    @IBOutlet var activity: UIActivityIndicatorView!

    let browserUtil = BrowserUtil()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
            let req = URLRequest(url:url)
            webView.loadRequest(req)
            searchBar.text = url.absoluteURL.absoluteString
        } else {
            if var query = urlString {
                query = query.replacingOccurrences(of: " ", with: "+")
                let url = URL(string: "http://www.google.com/search?q=\(query)")
                let request = URLRequest(url: url!)
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

}

