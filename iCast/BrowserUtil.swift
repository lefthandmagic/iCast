//
//  BrowserUtil.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/28/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import Foundation

class BrowserUtil {

    static func createURL(string: String) -> URL {
        var urlString: String

        if string.hasPrefix("http") {
            urlString = string
        } else {
            urlString = "http://" + string
        }
        print(urlString)
        return URL(string: urlString)!
    }
}
