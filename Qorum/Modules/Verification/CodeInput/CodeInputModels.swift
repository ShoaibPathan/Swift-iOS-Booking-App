//
//  CodeInputModels.swift
//  Qorum
//
//  Created by Stanislav on 09.04.2018.
//  Copyright (c) 2018 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

enum CodeInput {
    
    static let resendTimeout: TimeInterval = 30
    static let submittingTimeout: TimeInterval = 60
    
    struct Request {
        let code: String
    }
    
    enum Response {
        
        /// code is invalid
        case invalidCode
        
        /// no pending verifications
        case noPendingVerifications
        
        /// too many requests API usage limit
        case reachedRequestsLimit
        
        /// error received
        case error(Error)
        
        /// phone verification is successful
        case success(needsVerifyEmail: Bool)
        
        /// time left to resubmit will be allowed
        case secondsToSubmit(Int)
        
        /// allows user to submit a verification code after a failed attempt
        case mayReSubmit
        
        /// time left to resend will be allowed
        case secondsToResend(Int)
        
        /// allows user to resend a code
        case mayResend
    }
    
    enum ViewModel {
        
        /// custom warning to display
        case warning(String)
        
        /// custom warning to display
        case failure(String)
        
        /// resend verification code is available after a short delay
        case resubmitButton(isEnabled: Bool, text: String)
        
        /// resend button title and state
        case resendButton(isEnabled: Bool, text: String)
        
        /// allows to verify email
        case mayVerifyEmail
        
        /// allows to close screen
        case mayClose
    }
    
}
