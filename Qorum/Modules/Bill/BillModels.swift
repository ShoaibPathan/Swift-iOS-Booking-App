//
//  BillModels.swift
//  Qorum
//
//  Created by Dima Tsurkan on 11/30/17.
//  Copyright (c) 2017 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

enum BillModels {
    
    // MARK: - Fetch Checkin
    
    struct Bill {
        
        struct Request {
            
            /// checkin for bill
            let checkin: Checkin
        }
        
        typealias Response = APIResult<Checkin>
        
        enum ViewModel {
            
            /// indicates successful checkout for checkin
            case success(Checkin)
            
            /// displays alert
            case alert(title: String, message: String)
            
            /// indicates that alert is displayed in presenter.
            /// used for updating checkin state on closing the tab
            case alertDisplayed
            
            /// indicates remote checkout or checkout by beacon/geofencing
            case autoClosed
        }
        
    }
    
    // MARK: - Check Out
    
    struct CheckOut {
        
        struct Request {
            
            /// checkin id for checkout
            let checkinId: Int
            
            /// checkout description
            let method: String?
        }
        
        enum Response {
            case success(Checkin)
            case error(Error)
            case emptyTab(Error)
        }
        
        typealias ViewModel = Bill.ViewModel
        
    }
    
    // MARK: - Gratuity
    
    struct Gratuity {
        
        struct Request {
            let checkinId: Int
            let tip: Tip
        }
        
        typealias Response = APIResult<()>
        
        enum ViewModel {
            case success
            case alert(title: String, message: String)
        }
        
    }
    
    // MARK: - Ridesafe
    
    enum Ridesafe {
        
        struct ViewModel {
            let checkinId: Int
            let data: Checkin.RideSafeData
        }
        
    }
    
    enum Tip: Equatable {
        case cents(Int)
        case percents(Int)
        
        var isCustom: Bool {
            switch self {
            case .cents: return true
            case .percents: return false
            }
        }
        
    }
    
}