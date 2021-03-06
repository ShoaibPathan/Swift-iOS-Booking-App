//
//  UberOrderRouter.swift
//  Qorum
//
//  Created by Vadym Riznychok on 12/4/17.
//  Copyright (c) 2017 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

@objc protocol UberOrderRoutingLogic {
    func openUberApp()
    func navigateToAd(source: UberOrderViewController, destination: UberAdController)
    func routeBack()
}

protocol UberOrderDataPassing {
    var dataStore: UberOrderDataStore? { get }
}

class UberOrderRouter: NSObject, UberOrderRoutingLogic, UberOrderDataPassing {
    weak var viewController: UberOrderViewController?
    var dataStore: UberOrderDataStore?
  
    // MARK: Routing
  
    //func routeToSomewhere(segue: UIStoryboardSegue?)
    //{
    //  if let segue = segue {
    //    let destinationVC = segue.destination as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //  } else {
    //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //    navigateToSomewhere(source: viewController!, destination: destinationVC)
    //  }
    //}

    // MARK: Navigation
    
    func openUberApp() {
        let app = UIApplication.shared
        if let uberURL = URL(string: "uber://"), app.canOpenURL(uberURL) {
            app.open(uberURL, options: [:], completionHandler: nil)
        } else if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/us/app/uber/id368677368?mt=8") {
            app.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    func navigateToAd(source: UberOrderViewController, destination: UberAdController) {
        destination.uberData = UberRequestData(type: viewController!.selectedType!,
                                               pickup: viewController!.pickupMarker.position,
                                               dropoff: viewController!.destinationMarker.position,
                                               pickupAddress: viewController!.uberAdressesView.topField.text,
                                               dropoffAddress: viewController!.uberAdressesView.bottomField.text,
                                               seatsCount: viewController!.seatsCount,
                                               qorumRideType: viewController!.rideType)
        destination.checkin = viewController!.checkin
        destination.rideType = viewController!.rideType
        destination.interactor = viewController!.interactor
        destination.router = self
        viewController!.navigationController?.pushViewController(destination, animated: true)
    }
    
    func routeBack() {
        guard let viewController = viewController else { return }
        guard let navigationVC = viewController.navigationController else {
            fatalError("missing navigation controller!")
        }
        if let venueDetailsVC = navigationVC.find(VenueDetailsViewController.self) {
            navigationVC.popToViewController(venueDetailsVC, animated: true)
        } else if let venuesVC = navigationVC.find(VenuesViewController.self) {
            navigationVC.popToViewController(venuesVC, animated: true)
        } else {
            navigationVC.popViewController(animated: true)
        }
    }
    
//    func isUberDownloaded() -> Bool {
//        let app = UIApplication.shared
//        if let uberURL = URL(string: "uber://"), app.canOpenURL(uberURL) {
//            return true
//        } else {
//            return false
//        }
//    }
  
    //func navigateToSomewhere(source: UberOrderViewController, destination: SomewhereViewController)
    //{
    //  source.show(destination, sender: nil)
    //}
  
    // MARK: Passing data
  
    //func passDataToSomewhere(source: UberOrderDataStore, destination: inout SomewhereDataStore)
    //{
    //  destination.name = source.name
    //}
    
    
}
