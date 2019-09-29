//
//  BeaconsOnboardingPresenter.swift
//  Qorum
//
//  Created by Vadym Riznychok on 6/8/18.
//  Copyright (c) 2018 Bizico. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol BeaconsOnboardingPresentationLogic {
    func presentLocationRequest()
    func presentBARViewController()
    func presentLoader(shouldPresent: Bool)
}

class BeaconsOnboardingPresenter: BeaconsOnboardingPresentationLogic {
    weak var locationController: BOLocationAccessDisplayLogic?
    weak var backgroundRefreshController: BOBackgroundRefreshDisplayLogic?
  
    // MARK: Do something
  
    func presentLocationRequest() {
        locationController?.displayLocationRequest()
    }
    
    func presentBARViewController() {
        locationController?.displayBARViewController()
    }
    
    func presentLoader(shouldPresent: Bool) {
        locationController?.displayLoader(shouldDisplay: shouldPresent)
    }
}