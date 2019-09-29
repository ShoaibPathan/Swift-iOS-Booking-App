//
//  LocationBlock
//  Qorum
//
//  Created by Stanislav on 31.01.2018.
//  Copyright (c) 2018 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

struct LocationBlock {
    
    struct Request {
        let email: String
    }
    
    enum Response {
        case invalidEmail
        case invalidLocation
        case error(Error)
        case success
    }
    
    enum ViewModel {
        case warning(String)
        case success
    }

}