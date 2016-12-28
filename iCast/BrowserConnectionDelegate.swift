//
//  BrowserConnectionDelegate.swift
//  iCast
//
//  Created by Praveen Murugesan on 12/28/16.
//  Copyright © 2016 Praveen. All rights reserved.
//

import Foundation

class BrowserConnectionDelegate : NSObject, NSURLConnectionDelegate {

    func connection(_ connection: NSURLConnection, canAuthenticateAgainstProtectionSpace protectionSpace: URLProtectionSpace) -> Bool{
        print("canAuthenticateAgainstProtectionSpace method Returning True")
        return true
    }


    func connection(_ connection: NSURLConnection, didReceive challenge: URLAuthenticationChallenge){

        print("did autherntcationchallenge = \(challenge.protectionSpace.authenticationMethod)")

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust  {
            print("send credential Server Trust")
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            challenge.sender!.use(credential, for: challenge)

        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic{
            print("send credential HTTP Basic")
            let defaultCredentials: URLCredential = URLCredential(user: "username", password: "password", persistence:URLCredential.Persistence.forSession)
            challenge.sender!.use(defaultCredentials, for: challenge)

        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM{
            print("send credential NTLM")

        } else{
            challenge.sender!.performDefaultHandling!(for: challenge)
        }
    }


}
