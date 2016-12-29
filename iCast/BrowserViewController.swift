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

        setWebViewProperties()
        setSearchBarProperties()

        let url = BrowserUtil.createURL(string:"https://www.youtube.com")
        let req = URLRequest(url:url)
        webView.loadRequest(req)
        searchBar.text = url.absoluteURL.absoluteString
    }

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


    func webViewDidStartLoad(_ webView : UIWebView) {
        activity.startAnimating()
    }

    func webViewDidFinishLoad(_ webView : UIWebView) {
        activity.stopAnimating()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = searchBar.text
        let url = BrowserUtil.createURL(string: text!)
        let req = URLRequest(url:url)
        webView.loadRequest(req)
        searchBar.text = url.absoluteURL.absoluteString
    }

}

