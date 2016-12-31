//
//  BrowserUtil.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/28/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import Foundation
import UIKit

class BrowserUtil {

    static func createURL(string: String) -> URL? {
        var urlString: String
        if string.hasPrefix("http") {
            urlString = string
        } else {
            urlString = "http://" + string
        }
        print(urlString)

        if verifyUrl(urlString: urlString) {
            print("URL Verification passed \(urlString)")
            return URL(string: urlString)
        } else {
            print("URL Verification failed \(urlString)")
            return nil
        }
    }

    static private func verifyUrl (urlString: String?) -> Bool {
        guard let urlString = urlString else {return false}
        guard let url = URL(string: urlString) else {return false}
        if !UIApplication.shared.canOpenURL(url) {return false}

        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return predicate.evaluate(with: urlString)    }
}
