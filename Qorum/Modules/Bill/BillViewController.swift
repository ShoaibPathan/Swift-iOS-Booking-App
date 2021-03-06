//
//  BillViewController.swift
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
import Mixpanel
import SDWebImage

enum CheckinState: Equatable {
    
    /// normal state
    case idle
    
    /// updating
    case updating
    
    /// ready to close
    case needsClose(openUber: Bool)
    
    /// in the middle of closing
    case closing(openUber: Bool)
    
    /// closed checkin
    case closed
    
    var mayUpdate: Bool {
        switch self {
        case .idle: return true
        case .updating,
             .needsClose,
             .closing,
             .closed: return false
        }
    }
    
    var mayClose: Bool {
        switch self {
        case .idle,
             .updating,
             .needsClose: return true
        case .closing,
             .closed: return false
        }
    }
    
}

protocol BillDisplayLogic: class {
    
    /// alert for failed payment
    var paymentFailureAlert: UIAlertController? { get set }
    var isVisible: Bool { get }
    
    /// Displays Bill data
    ///
    /// - Parameter viewModel: Bill model
    func displayBill(viewModel: BillModels.Bill.ViewModel)
    
    /// Displays checkout
    ///
    /// - Parameter viewModel: checkout model
    func displayCheckOut(viewModel: BillModels.CheckOut.ViewModel)
    
    /// Displays Tips amount
    ///
    /// - Parameter viewModel: tips model
    func displayGratuity(viewModel: BillModels.Gratuity.ViewModel)
    
    /// Displays ridesafe state
    ///
    /// - Parameter viewModel: ridesafe model
    func displayRidesafe(viewModel: BillModels.Ridesafe.ViewModel)
    
    /// Opens Payment Details Screen
    func routeToPayments()
}

class BillViewController: BaseViewController, SBInstantiable {
    
    static let storyboardName = StoryboardName.bill
    var interactor: BillBusinessLogic?
    var router: (NSObjectProtocol & BillRoutingLogic & BillDataPassing)?
    
    /// Periodically update timer
    var billUpdateTimer: Timer?
    
    /// Free Uber Timer
    var uberTimeLeftTimer: Timer?
    
    /// time left for free Uber ride
    var timeLeft = Date()
    
    var checkinState = CheckinState.idle {
        didSet {
            guard oldValue != checkinState else { return }
            switch checkinState {
            case .idle, .closed:
                hideLoader()
            case .closing:
                showLoader("Closing Tab")
            case .updating, .needsClose:
                break
            }
        }
    }
    
    var foregroundNotification: NSObjectProtocol?
    
    var updateBillOnSwipeEnabled: Bool {
        return AppConfig.fakeCheckinsEnabled
    }
    
    //MARK: - Outlets
    @IBOutlet weak var advertImage: UIImageView!
    @IBOutlet weak var closeTabButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var pullToUpdateHint: ArrowsView!
    
    @IBOutlet weak var tabWrapper: UIScrollView!
    
    @IBOutlet weak var timeForFreeUber: UILabel!
    @IBOutlet weak var hintForFreeUber: UILabel!
    
    @IBOutlet weak var uberButton: UIButton!
    @IBOutlet weak var uberLogo: UIImageView!
    @IBOutlet weak var uberDiscountLabel: UILabel!
    @IBOutlet weak var checkinGuide: UIView!
    @IBOutlet weak var billGuide: UIView?
    
    private weak var tabController: BillContentViewController?
    private weak var checkinGuideOverlay: BillCheckinGuideOverlay?
    private weak var uberGuideOverlay: BillUberGuideOverlay?
    
    weak var paymentFailureAlert: UIAlertController?
    
    let refreshHeader = RefreshHeaderView()
    
    // MARK: - Object lifecycle
    
    deinit {
        billUpdateTimer?.invalidate()
        uberTimeLeftTimer?.invalidate()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let viewController = self
        let interactor = BillInteractor()
        let presenter = BillPresenter()
        let router = BillRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        QorumNotification.tabTicketUpdated.add(observer: self, selector: #selector(updateBill))
        QorumNotification.tabTicketClosed.add(observer: self, selector: #selector(checkoutFromNotif))
        foregroundNotification = Notification.Name.UIApplicationWillEnterForeground.addObserver { [weak self] _ in
            self?.timeForFreeUber.isHidden = true
            self?.hintForFreeUber.isHidden = true
            self?.updateBill()
        }
        
        navigationController?.isNavigationBarHidden = true
        
        if UserDefaults.standard.bool(for: .didShowCheckinGuideKey) != true {
            displayCheckinGuide()
            UserDefaults.standard.set(true, for: .didShowCheckinGuideKey)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBillInternal()
        switch checkinState {
        case .updating:
            if checkinGuide.isHidden {
                // TODO: - Do we really need to block user interaction here?
                showLoader("Updating Tab")
                // TODO: - Also check about displaying the checkin passed from venue details
            }
        case .needsClose(let openUber):
            checkout(openUber: openUber)
        case .idle, .closing, .closed: break
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        if foregroundNotification != nil {
            NotificationCenter.default.removeObserver(foregroundNotification!)
            foregroundNotification = nil
        }
        billUpdateTimer?.invalidate()
        uberTimeLeftTimer?.invalidate()
    }
    
    // MARK: - Configs
    
    func configureView() {
        tabController = childViewControllers.find(BillContentViewController.self)
        tabController?.delegate = self
        
        checkinGuideOverlay = childViewControllers.find(BillCheckinGuideOverlay.self)
        checkinGuideOverlay?.delegate = self
        
        uberGuideOverlay = childViewControllers.find(BillUberGuideOverlay.self)
        uberGuideOverlay?.delegate = self
        dismissUberOverlay()
        
        automaticallyAdjustsScrollViewInsets = false
        let defaults = UserDefaults.standard
        let adURL: URL? = AppConfig.billAdFetchEnabled ? defaults.advertTabPhotoURL : nil
        advertImage.sd_setImage(with: adURL,
                                placeholderImage: AppConfig.billAdPlaceholder.image,
                                options: [],
                                completed: nil)
        
        hintForFreeUber.attributedText = NSMutableAttributedString(
            ("remaining for ", UIFont.montserrat.light(10), UIColor.white),
            ("FREE UBER", UIFont.montserrat.semibold(10), UIColor.white)
        )
        
        pullToUpdateHint.transform = CGAffineTransform(rotationAngle: .pi)
        if UserDefaults.standard.bool(for: .isTabEverPulledToUpdateBill) {
            pullToUpdateHint.hide()
        }
        
        configureRefreshControl()
    }
    
    private func configureRefreshControl() {
        guard updateBillOnSwipeEnabled else {
            tabWrapper.bounces = false
            return
        }
        pullToUpdateHint.isHidden = UserDefaults.standard.bool(for: .isTabEverPulledToUpdateBill)
        refreshHeader.add(to: tabWrapper,
                          addingTarget: self,
                          action: #selector(updateBillOnSwipe),
                          blocksOnRefresh: tabWrapper)
    }
    
    // MARK: - Update bill
    
    @objc func updateBillOnSwipe() {
        UserDefaults.standard.set(true, for: .isTabEverPulledToUpdateBill)
        updateBillInternal()
    }
    
    @objc func updateBill() {
        updateBillInternal()
        if checkinState == .updating, !isLoaderVisible {
            refreshHeader.startAnimating()
        }
        if UIApplication.shared.applicationState != .active {
            billUpdateTimer?.invalidate()
            billUpdateTimer = nil
        }
    }
    
    private func updateBillInternal() {
        guard
            let checkin = router?.dataStore?.checkin,
            checkinState.mayUpdate else { return }
        checkinState = .updating
        venueName.text = checkin.venue?.name
        let request = BillModels.Bill.Request(checkin: checkin)
        interactor?.updateBill(request: request)
        scheduledBillUpdateTimerWithTimeInterval()
    }
    
    // MARK: Additional Detail Logic
    
    private func displayAlert(title: String,
                              message: String?,
                              retryAction: @escaping ()->()) {
        let actions: [UIAlertController.CustomAction]
        actions = [("Cancel", .cancel, nil),
                   ("Try again", .default, retryAction)]
        UIAlertController.presentAsAlert(title: title,
                                         message: message,
                                         actions: actions)
    }
    
    func displayCheckinGuide() {
        checkinGuide.alpha = 1.0
        checkinGuide.isHidden = false
        delayToMainThread(5) { [weak self] in
            self?.dismissCheckinOverlay()
        }
    }
    
    func displayBillGuide() {
        billGuide?.alpha = 1.0
        billGuide?.isHidden = false
        delayToMainThread(5) { [weak self] in
            self?.dismissUberOverlay()
        }
    }
    
    // MARK: Scheduler
    
    private func scheduledBillUpdateTimerWithTimeInterval() {
        billUpdateTimer?.invalidate()
        billUpdateTimer = Timer.scheduledTimer(timeInterval: Time(1, .minutes)[in: .seconds],
                                               target: self,
                                               selector: #selector(updateBill),
                                               userInfo: nil,
                                               repeats: false)
        // the updateBill() will call updateBillInternal() which will restart the timer manually
    }
    
    // MARK: - Actions
    @objc func checkoutFromNotif() {
        guard
            let checkinId = router?.dataStore?.checkin?.checkin_id,
            checkinState.mayClose else { return }
        let request = BillModels.CheckOut.Request(checkinId: checkinId, method: "Manually Closed by Bartender")
        interactor?.checkoutFromNotif(request: request)
    }
    
    @IBAction func checkOut() {
        checkout(openUber: false, method: "Manually Tap Close Tab Button")
    }
    
    @IBAction func openUber() {
        checkout(openUber: true, method: "Manually Tap Uber Request Button")
    }
    
    /// Request for checkout
    ///
    /// - Parameters:
    ///   - openUber: if uber needs to be opened after checkout complete
    ///   - method: checkout description used for analytics
    private func checkout(openUber: Bool, method: String? = nil) {
        guard checkinState.mayClose else { return }
        guard User.stored.isPhoneVerified else {
            verifyPhone()
            checkinState = .needsClose(openUber: openUber)
            return
        }
        checkinState = .closing(openUber: openUber)
        
        if let checkinId = router?.dataStore?.checkin?.checkin_id {
            let request = BillModels.CheckOut.Request(checkinId: checkinId, method: method)
            interactor?.checkout(request: request)
        } else {
            cancelCheckingOut()
        }
    }
    
    
    /// Asks user to verify his phone number by displaying an alert.
    private func verifyPhone() {
        let verifyPhoneMessage = "Please verify your phone before closing the Tab to keep your account and Qorum safe."
        let cancelAction, verifyAction: UIAlertController.CustomAction
        cancelAction = ("Cancel", .cancel, { [weak self] in
            self?.cancelCheckingOut()
        })
        verifyAction = ("Verify Phone", .default, { [weak router] in
            router?.routeToPhoneVerification()
        })
        UIAlertController.presentAsAlert(message: verifyPhoneMessage,
                                         actions: [cancelAction, verifyAction])
    }
    
    @IBAction func close() {
        router?.navigateBack()
    }
    
    func cancelCheckingOut() {
        if checkinState != .closed {
            checkinState = .idle
        }
    }
    
    func updateCheckinForAutoClosed() {
        if let checkin = AppDelegate.shared.checkinHash.values.first(where: { $0.checkin_id == router?.dataStore?.checkin?.checkin_id }),
            let venue = checkin.venue {
            checkin.autoClosed = true
            AppDelegate.shared.checkinHash.updateValue(checkin, forKey: venue.venue_id)
        }
    }
    
}

// MARK: - BillDisplayLogic
extension BillViewController: BillDisplayLogic {
    
    var isVisible: Bool {
        return UIApplication.shared.topMostFullScreenViewController === self
    }
    
    func displayBill(viewModel: BillModels.Bill.ViewModel) {
        refreshHeader.stopAnimating()
        if checkinState == .updating {
            checkinState = .idle
        }
        switch viewModel {
        case let .success(checkin):
            paymentFailureAlert?.dismiss(animated: false, completion: .none)
            if let name = checkin.venue?.name {
                venueName.text = name
            }
            tabController?.update(with: checkin.bill!)
            if checkin.checkout_time != nil {
                checkoutFromNotif()
            } else {
                let isRidesafeUnlockable = checkin.uberDiscountValue != .none
                if isRidesafeUnlockable && UserDefaults.standard.bool(for: .didShowBillGuideKey) != true {
                    UserDefaults.standard.set(true, for: .didShowBillGuideKey)
                    displayBillGuide()
                }
            }
        case let .alert(title, message):
            displayAlert(title: title,
                         message: message,
                         retryAction: updateBill)
        case .alertDisplayed:
            break
        case .autoClosed:
            updateCheckinForAutoClosed()
        }
    }
    
    func displayCheckOut(viewModel: BillModels.CheckOut.ViewModel) {
        guard checkinState != .closed else { return }
        let newCheckinState: CheckinState
        switch viewModel {
        case .success(_):
            paymentFailureAlert?.dismiss(animated: false, completion: .none)
            if checkinState == .closing(openUber: true) {
                router?.routeToUber(source: self)
            } else {
                router?.routeToClosedTab()
            }
            UserDefaults.standard.set(false, for: .didShowCheckinGuideKey)
            newCheckinState = .closed
        case let .alert(title, message):
            let checkout = {
                self.checkout(openUber: false)
            }
            displayAlert(title: title,
                         message: message,
                         retryAction: checkout)
            newCheckinState = .idle
        case .alertDisplayed:
            newCheckinState = .idle
        case .autoClosed:
            newCheckinState = .idle
        }
        checkinState = newCheckinState
    }
    
    func displayGratuity(viewModel: BillModels.Gratuity.ViewModel) {
        switch viewModel {
        case .success:
            updateBillInternal()
        case let .alert(title, message):
            hideLoader()
            let okAction: UIAlertController.CustomAction
            okAction = ("OK", .cancel, { [weak self] in
                self?.showLoader("Updating Tab")
                self?.updateBillInternal()
            })
            UIAlertController.presentAsAlert(title: title,
                                             message: message,
                                             actions: [okAction])
        }
    }
    
    func displayRidesafe(viewModel: BillModels.Ridesafe.ViewModel) {
        switch viewModel.data {
        case let .enabled(discount):
            uberDiscountLabel.text = "$\(discount) MAX"
            uberDiscountLabel.isHidden = false
            uberLogo.image = UIImage(named: "free_uber")
            timeForFreeUber.isHidden = true
            hintForFreeUber.isHidden = true
        case let .waiting(timeLeft):
            uberDiscountLabel.isHidden = true
            uberLogo.image = UIImage(named: "paid_uber")
            timeForFreeUber.isHidden = false
            hintForFreeUber.isHidden = false
            uberTimeLeftTimer?.invalidate()
            var time = timeLeft
            uberTimeLeftTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if time > 0 {
                    let minutes = time / 60
                    let seconds = time % 60
                    self?.timeForFreeUber.text = String(format:"%02i:%02i", minutes, seconds)
                    time -= 1
                } else {
                    self?.updateBill()
                    timer.invalidate()
                }
            }
            uberTimeLeftTimer!.fire()
        case .disabled:
            uberDiscountLabel.isHidden = true
            uberLogo.image = UIImage(named: "paid_uber")
            timeForFreeUber.isHidden = true
            hintForFreeUber.isHidden = true
        }
    }
    
    func routeToPayments() {
        router?.routeToPayments()
    }
    
}

// MARK: - TipsDelegate
extension BillViewController: TipsDelegate {
    
    var billTotalAmount: Float? {
        if let totals = router?.dataStore?.checkin?.bill?.totals, totals.subTotal + totals.freeDrinksPrice > 0 {
            return Float((totals.subTotal + totals.freeDrinksPrice) / 100)
        } else {
            return .none
        }
    }
    
    func didStartCustomChoiceTipsEditing() {
        UIView.animate(withDuration: 0.5) { [weak self] in self?.advertImage.isHidden = true }
    }
    
    func didCancelCustomChoiceTipsEditing() {
        UIView.animate(withDuration: 0.5) { [weak self] in self?.advertImage.isHidden = false }
    }
    
    func didSelect(tip: BillModels.Tip) {
        guard let checkin = router?.dataStore?.checkin else { return }
        switch tip {
        case let .percents(percents):
            debugPrint("didSelectFixedChoiceTips", "\(percents)%")
        case let .cents(cents):
            UIView.animate(withDuration: 0.5) { [weak self] in self?.advertImage.isHidden = false }
            let dollars = Float(Money(Double(cents), .cents)[in: .dollars])
            debugPrint("didSelectFreeChoiceTips", "$\(dollars)")
        }
        let request = BillModels.Gratuity.Request(checkinId: checkin.checkin_id, tip: tip)
        showLoader("Updating Tab")
        interactor?.updateGratuity(request: request)
    }
    
}

// MARK: - BillCheckinGuideOverlayDelegate
extension BillViewController: BillCheckinGuideOverlayDelegate {
    
    func dismissCheckinOverlay() {
        guard let viewToHide = checkinGuide, !viewToHide.isHidden else { return }
        checkinGuide?.alpha = 1.0
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.checkinGuide.alpha = 0
        }) { [weak self] _ in
            if let viewToHide = self?.checkinGuide, !viewToHide.isHidden {
                self?.checkinGuide?.isHidden = true
                if self?.checkinState == .updating {
                    self?.refreshHeader.stopAnimating()
                    self?.showLoader("Updating Tab")
                }
            }
        }
    }
    
}

// MARK: - BillUberGuideOverlayDelegate
extension BillViewController: BillUberGuideOverlayDelegate {
    
    func dismissUberOverlay() {
        guard let viewToHide = billGuide, !viewToHide.isHidden else { return }
        billGuide?.alpha = 1.0
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.billGuide?.alpha = 0.0
        }) { [weak self] _ in
            if let viewToHide = self?.billGuide, !viewToHide.isHidden {
                self?.billGuide?.isHidden = true
            }
            self?.billGuide?.alpha = 1.0
        }
    }
    
}
