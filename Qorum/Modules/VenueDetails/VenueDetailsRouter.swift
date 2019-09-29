//
//  VenueDetailsRouter.swift
//  Qorum
//
//  Created by Dima Tsurkan on 11/16/17.
//  Copyright (c) 2017 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

@objc protocol VenueDetailsRoutingLogic {
    func routeToVenues()
    func navigateToBluetoothRequest(source: VenueDetailsViewController)
    func routeToVenueBill()
    func routeToFacebookSettings()
    func routeToAuth()
    func routeToMenu()
    func routeToAddPayments()
    func routeToPayments()
    func routeToUber()
    func routeToPhoto()
    func routeToEmailVerification()
}

protocol VenueDetailsDataPassing {
    var dataStore: VenueDetailsDataStore? { get set }
}

class VenueDetailsRouter: NSObject, VenueDetailsRoutingLogic, VenueDetailsDataPassing {
    
    weak var viewController: VenueDetailsViewController?
    var dataStore: VenueDetailsDataStore?
    
    // MARK: Routing
    
    func routeToVenues() {
        navigateToVenues(source: viewController!, destination: nil)
    }
    
    func navigateToBluetoothRequest(source: VenueDetailsViewController) {
        let vc = AccessViewController()
        vc.state = .bluetooth
        source.navigationController?.pushViewController(vc, animated: true)
    }
    
    func routeToVenueBill() {
        let destinationVC = BillViewController.fromStoryboard
        var destinationDS = destinationVC.router!.dataStore!
        passDataToBill(source: dataStore!, destination: &destinationDS)
        navigateToBill(source: viewController!, destination: destinationVC)
    }
    
    func routeToFacebookSettings() {
        viewController?.navigationController?.pushViewController(SettingsViewController.fromStoryboard, animated: true)
    }
    
    func routeToAuth() {
        let destinationVC = AuthViewController.fromStoryboard
        destinationVC.authorizeOnAppear = true
        navigateToAuth(source: viewController!, destination: destinationVC)        
    }
    
    func routeToMenu() {
        let destinationVC = MenuHeaderController.fromStoryboard
        destinationVC.venue = viewController?.venue
        navigateToMenu(source: viewController!, destination: destinationVC)
    }
    
    func routeToAddPayments() {
        let destinationVC = AddNewPaymentViewController.fromStoryboard
        navigateToAddPayments(source: viewController!, destination: destinationVC)
    }
    
    func routeToPayments() {
        let destinationVC = PaymentsViewController.fromStoryboard
        navigateToPayments(source: viewController!, destination: destinationVC)
    }
    
    func routeToUber() {
        let uberVC = UberOrderViewController.fromStoryboard
        uberVC.venue = viewController?.venue
        navigateToUber(source: viewController!, destination: uberVC)
    }
    
    /// Routes to the Profile scene and triggers `photoButtonPressed` action
    func routeToPhoto() {
        let profileVC = ProfileViewController.fromStoryboard
        viewController!.navigationController!.pushViewController(profileVC, animated: true)
        delayToMainThread(0.1) { [weak self] in
            guard let viewController = self?.viewController else { return }
            profileVC.photoButtonPressed(viewController)
        }
    }
    
    func routeToEmailVerification() {
        let destinationVC = EmailInputViewController.fromStoryboard.embeddedInNavigationController
        viewController?.present(destinationVC, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    func navigateToVenues(source: VenueDetailsViewController, destination: VenuesViewController?) {
        if source.navigationController?.popViewController(animated: true) != nil {
            source.removeFromParentViewController()
        } else {
            source.dismiss(animated: true, completion: nil)
        }
    }
    
    func navigateToBill(source: VenueDetailsViewController, destination: BillViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    func navigateToAuth(source: VenueDetailsViewController, destination: AuthViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    func navigateToMenu(source: VenueDetailsViewController, destination: MenuHeaderController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    func navigateToAddPayments(source: VenueDetailsViewController, destination: AddNewPaymentViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    func navigateToPayments(source: VenueDetailsViewController, destination: PaymentsViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    func navigateToUber(source: VenueDetailsViewController, destination: UberOrderViewController) {
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    // MARK: - Passing data
    
    /// Passes `checkin` from Venue details to Bill.
    ///
    /// - Parameters:
    ///   - source: The Venue details scene's data store.
    ///   - destination: The Bill scene's data store.
    func passDataToBill(source: VenueDetailsDataStore, destination: inout BillDataStore) {
        destination.checkin = source.checkin
    }
}