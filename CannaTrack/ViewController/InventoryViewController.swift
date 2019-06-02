//
//  InventoryViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/20/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CloudKit
import Foundation




final class InventoryViewController: UIViewController {

	let productCategoryCellIdentifier = "ProductCategoryCollectionViewCell"
	let inventoryCellIdentifier = "InventoryCollectionViewCell"
	let headerIdentifier = "ProductSectionHeaderView"

	//preview action container view work
	var viewPropertyAnimator: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 3, curve: .easeInOut)

	var productChangeConfirmationAnimator: UIViewPropertyAnimator!

	var indexPathForUpdateActionCell: IndexPath? {
		didSet {
			print("new indexpath for update action cell is \(self.indexPathForUpdateActionCell!)")
		}
	}

	var cellForUpdateAction: InventoryCollectionViewCell? {
		didSet {
			if let cell = self.cellForUpdateAction {
				self.indexPathForUpdateActionCell = self.productsCollectionView?.indexPath(for: cell)
				
//				cell.contentView.bringSubviewToFront(cell.confirmationIndicator ?? UIImageView(image: #imageLiteral(resourceName: "greenCheck")))
//				cell.confirmationIndicator.alpha = 0.0
//				productChangeConfirmationAnimator = handleAnimatorChange(using: cell)
//				productChangeConfirmationAnimator.startAnimation()

			} else {
				print("could not unwrap newValue for cellForUpdateAction in its didSet")
			}
		}
	}

	@IBOutlet var containerOptionsView: OptionsContainerView!

	var dynamicAnimator: UIDynamicAnimator!
	var snapBehavior: UISnapBehavior!
	var itemBehavior: UIDynamicItemBehavior!

	var cloudKitObserver: NSObjectProtocol?

	var originalAddButtonPosition: CGPoint!
	var originalAddButtonSize: CGSize! = CGSize(width: 60, height: 60)

	var dateFormatter = DateFormatter()
	var activityView = UIActivityIndicatorView()

	var inventoryDatabaseChangeToken: CKServerChangeToken?

	var inventoryFilterOption: FilterOption = .none


	var activeCategoryDisplayed: Product.ProductType? {
		didSet {
			self.productsCollectionView.performBatchUpdates({
				self.productsCollectionView.reloadSections(NSIndexSet(index: 1) as IndexSet)
			}, completion: nil)
		}
	}


	var currentInventory: [Product]? {
		didSet {
			self.productsCollectionView.performBatchUpdates({
				self.productsCollectionView.reloadSections(NSIndexSet(index: 1) as IndexSet)
			}, completion: nil)
		}
	}

	var masterProductArray: [Product]? {
		willSet(newProductArray) {
			globalMasterInventory = newProductArray ?? []
		}
	}


	var categoriesInInventory: [Product.ProductType] = []

	//Preview Interaction work

	var productPreviewInteraction: UIPreviewInteraction?


	//------------------------------------------

	@IBOutlet var productsCollectionView: UICollectionView!

	@IBOutlet var filterButton: UIBarButtonItem!

	@IBOutlet var addProductButton: AddProductFloatingButton!




	override func viewDidLoad() {
        super.viewDidLoad()

		//obligatory random setup of view

		self.inventoryFilterOption = .none

		setupInventoryCollectionView()

		setupAddButtonForViewController()



		setupPeekAndPopForInventoryCollection()


		productPreviewInteraction = UIPreviewInteraction(view: addProductButton)
		productPreviewInteraction?.delegate = self


		setupDynamicAnimator()

		//activity view setup and CKQuery, other
		setupActivityView()



		masterProductArray = []

		activityView.startAnimating()

		CloudKitManager.shared.retrieveAllProducts { (product, shouldStopAnimating) in
			DispatchQueue.main.async {
				if let product = product {
					guard let productsArray = self.masterProductArray else { return }
					if !productsArray.contains(product) {
						print("retreieved product, about to call update collectionview")

						self.masterProductArray?.append(product)
						self.updateInventoryCollectionView()
					}
				}
				if let stopAnimating = shouldStopAnimating {
					if stopAnimating {
						self.activityView.stopAnimating()
					}
				}
			}
		}
		setupAnimatorForButtonPreviewInteraction()
		setupAnimatorForProductChangeConfirmation()

    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))
		self.view.addSubview(containerOptionsView)


		self.containerOptionsView.alpha = 0.0
		view.bringSubviewToFront(addProductButton)
		snapAddButtonToInitialPosition(button: addProductButton, animator: addProductButton.propertyAnimator, dynamicAnimator: dynamicAnimator)

		CloudKitManager.shared.setupFetchOperation(with: self.masterProductArray?.compactMap({$0.toCKRecord().recordID}) ?? [], completion: { (fetchedProductArray, error) in
			if let error = error {
				let alertView = UIAlertController(title: "Fetch Operation Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
				DispatchQueue.main.async {
					self.present(alertView, animated: true, completion:nil)
				}

			} else if let fetchedProductArray = fetchedProductArray {
				DispatchQueue.main.async {
					self.masterProductArray = fetchedProductArray
					//					self.updateInventoryCollectionView()
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: CloudKitNotifications.ProductChange), object: nil)
				}
			} else {
				print("wut happened")
			}
		})

	}


	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
//		CloudKitManager.shared.fetchProductCKQuerySubscriptions()
		fetchChanges(in: CloudKitManager.privateDatabase.databaseScope) {
			DispatchQueue.main.async {
				self.updateInventoryCollectionView()
			}
		}
		NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationForInventoryChanges), name: NSNotification.Name(rawValue: CloudKitNotifications.ProductChange), object: nil)

//		CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope) {
//			print("new shared fetch Changes completion block executed")
//			DispatchQueue.main.async {
//				self.updateInventoryCollectionView()
//			}
//		}




	}


	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		CloudKitManager.shared.unsubscribeToProductUpdates()
	}

	func fetchChanges(in databaseScope: CKDatabase.Scope, completion: @escaping () -> Void) {
		CloudKitManager.shared.fetchChanges(in: databaseScope) {
			print("CKManager fetchChanges method executed by remote notification")
		}
	}




	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		originalAddButtonPosition = CGPoint(x: size.width - 25 - ((size.width * 0.145) / 2.0), y: size.height - 60 - ((size.height * 0.067) / 2.0))
		dynamicAnimator.removeBehavior(snapBehavior)
		snapBehavior = UISnapBehavior(item: addProductButton, snapTo: originalAddButtonPosition)
		dynamicAnimator.addBehavior(snapBehavior)
		print("view is transitioning orientation")
	}

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is ProductDetailViewController {
			guard let selectedCollectionViewCell = sender as? InventoryCollectionViewCell,
				let indexPath = productsCollectionView.indexPath(for: selectedCollectionViewCell)
				else { preconditionFailure("Expected sender to be a valid table view cell") }

			guard let productDetailViewController = segue.destination as? ProductDetailViewController
				else { preconditionFailure("Expected a ColorItemViewController") }

			cellForUpdateAction = selectedCollectionViewCell
			productDetailViewController.inventoryManagerDelegate = self
			productDetailViewController.editMassDelegate = self
			productDetailViewController.activeDetailProduct = currentInventory?[indexPath.item]

		} else if segue.destination is AddProductUsingTextViewController {
			guard let addProductVC = segue.destination as? AddProductUsingTextViewController else { preconditionFailure("Expected AddProductUsingTextVC") }
			addProductVC.inventoryManagerDelegate = self
		}

	}




	@IBAction func filterInventoryButtonTapped(_ sender: Any) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let filterOptionsVC = storyboard.instantiateViewController(withIdentifier: filterOptionsTableViewIdentifier) as! FilterOptionsTableViewController
		filterOptionsVC.modalPresentationStyle = .popover
		filterOptionsVC.popoverPresentationController?.barButtonItem = filterButton
		filterOptionsVC.filterDelegate = self

		self.present(filterOptionsVC, animated: true)

	}




}


// !!MARK - CollectionView Delegate and Data Source methods

extension InventoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {


	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let inventory = currentInventory else { return 0 }
		return (section == 0) ? categoriesInInventory.count : inventory.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)

		switch sectionForCell {
		case .category:
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: productCategoryCellIdentifier, for: indexPath) as? ProductCategoryCollectionViewCell else { fatalError("could not instantiate category collection view cell") }

			let categoriesPresent = categoriesInInventory[indexPath.row].rawValue

			cell.categoryLabel.text = categoriesPresent


			//!MARK: - Generalized Cell Setup perform here
			cell.backgroundColor = .lightGray
			cell.layer.cornerRadius = 12
			cell.layer.masksToBounds = true

			return cell

		case .product:
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: inventoryCellIdentifier, for: indexPath) as? InventoryCollectionViewCell else { fatalError("could not instantiate inventory collection view cell") }

			guard let productForIndex = currentInventory?[indexPath.item] else {
//				cell.inventoryProductLabel.text = "No Inventory"
				return cell
			}
			cell.inventoryProductLabel.text = productForIndex.productType.rawValue
			cell.productStrainNameLabel.text = productForIndex.strain.name
			cell.productMassRemainingLabel.text = "\(productForIndex.mass)"
			cell.doseCountLabel.text = "\(productForIndex.numberOfDosesTakenFromProduct)"

			let dateString: String = {
				guard let openedProductDate = globalMasterInventory[indexPath.row].dateOpened else {
					return "Unopened"
				}
				if openedProductDate == Date() {
					return "Today"
				} else {
					let yesterday = Calendar.current.isDateInYesterday(openedProductDate)
					if yesterday {
						return "Yesterday"
					}
				}
				return dateFormatter.string(from: openedProductDate)
			}()
			cell.dateOpenedLabel.text = dateString

			//!MARK: - Generalized Cell Setup perform here
			switch productForIndex.strain.race {
			case .hybrid:
				cell.backgroundColor = UIColor(named: "hybridColor")
			case .sativa:
				cell.backgroundColor = UIColor(named: "sativaColor")
			case .indica:
				cell.backgroundColor = UIColor(named: "indicaColor")
			}
			cell.layer.cornerRadius = 12
			cell.layer.masksToBounds = true

			return cell

		}
	}

	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier, for: indexPath) as? ProductHeaderCollectionReusableView else { fatalError("could not cast header as ProductHeaderCollectionReusableView")}

		//!MARK: - Generalized Cell Setup perform here
		supplementaryView.backgroundColor = .cyan
		supplementaryView.layer.cornerRadius = 12
		supplementaryView.layer.masksToBounds = true

		//!MARK: - Specific view element Setup perform here
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)
		switch sectionForCell {
		case .category:
			supplementaryView.sectionHeaderLabel.text = "Product Types in Inventory"
		case .product:
			guard let _ = activeCategoryDisplayed else {
				supplementaryView.sectionHeaderLabel.text = "No Category Selected"
				return supplementaryView
			}
			//set filtered text label option here
			supplementaryView.sectionHeaderLabel.text = activeCategoryDisplayed.map { $0.rawValue }
		}
		return supplementaryView
	}


	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)
		switch sectionForCell {
		case .category:
			activeCategoryDisplayed = categoriesInInventory[indexPath.row]
			//reuse this following code to filter
			let masterInventory = globalMasterInventory

			currentInventory = masterInventory.filter({ (productType) -> Bool in
					productType.productType == activeCategoryDisplayed
				})
		case .product:
			guard let cell = collectionView.cellForItem(at: indexPath) as? InventoryCollectionViewCell else {
				return
			}
			print("setting cellForUpdate action by tapping cell")
			cellForUpdateAction = cell
		}

	}


	enum InventoryCollectionSection: Int {
		case category = 0
		case product = 1
		init(indexPathSection: Int) {
			switch indexPathSection {
			case 0:
				self = .category
			case 1:
				self = .product
			default:
				self = .category
			}
		}
	}

}

extension InventoryViewController: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)

		switch sectionForCell {
		case .category:
			return CGSize(width: 100, height: 50)
		case .product:
			return CGSize(width: 120, height: 120)
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
	}

}

//!!MARK -- Helper methods for VC

extension InventoryViewController {

	func refreshUI() {
		loadViewIfNeeded()
		productsCollectionView.reloadData()
	}

	func updateCurrentInventory() -> [Product.ProductType] {
		if inventoryFilterOption == .none {
			self.currentInventory = masterProductArray
		}
		guard let inventory = masterProductArray else { return [] }
		var categories: Set<Product.ProductType> = []
		for product in inventory {
			categories.insert(product.productType)
		}
		return Array(categories).sorted(by: { $0.rawValue < $1.rawValue })
	}

	func handleSubscriptionNotification(ckqn: CKQueryNotification) {
		if ckqn.subscriptionID == CloudKitManager.subscriptionID {
			if let recordID = ckqn.recordID {
				switch ckqn.queryNotificationReason {
				case .recordCreated:
					DispatchQueue.main.async {
						print("record created notification received")
						self.updateInventoryCollectionView()
					}
				case .recordUpdated:
					DispatchQueue.main.async {
						print("record updated notification received")
						self.updateInventoryCollectionView()
					}
				case .recordDeleted:
					DispatchQueue.main.async {
						print("record deleted notification received")
						self.updateInventoryCollectionView()
					}
				}
			}
		}
	}


	fileprivate func stopAndFinishCurrentAnimations() {
		if addProductButton.propertyAnimator.isRunning {
			addProductButton.propertyAnimator.stopAnimation(false)
			addProductButton.propertyAnimator.finishAnimation(at: .start)
		}
	}



	fileprivate func updateInventoryCollectionView() {
		DispatchQueue.main.async {
			self.productsCollectionView.collectionViewLayout.invalidateLayout()
			self.productsCollectionView.performBatchUpdates({
				self.categoriesInInventory = self.updateCurrentInventory()
				self.productsCollectionView.reloadSections(NSIndexSet(index: 0) as IndexSet)
			}, completion: nil)
		}

	}

	fileprivate func setupActivityView() {
		activityView.center = self.view.center
		activityView.hidesWhenStopped = true
		activityView.style = .gray

		self.view.addSubview(activityView)
	}



	fileprivate func setupDynamicItemBehavior() {
		itemBehavior = UIDynamicItemBehavior(items: [addProductButton])
		itemBehavior.resistance = 0.5
		itemBehavior.allowsRotation = true
		dynamicAnimator.addBehavior(itemBehavior)
	}

	func handleAnimatorChange(using cell: InventoryCollectionViewCell) -> UIViewPropertyAnimator {
		let animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 3, delay: 1, options: [.allowAnimatedContent, .curveEaseInOut, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews], animations: {
			cell.confirmationIndicator.alpha = 1.0
		}, completion: { (animatingPosition) in
			if animatingPosition == .end {
			UIView.animate(withDuration: 5, delay: 2, options: [.allowAnimatedContent, .curveEaseInOut, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews], animations: {
				cell.confirmationIndicator.alpha = 0.0
			})
			} else {
				print("animating position is not at end, but closure it executing")
			}
		})
		guard let existingAnimator = self.productChangeConfirmationAnimator else { return animator }
		let animatorState = existingAnimator.state
		switch animatorState {
		case .inactive:
			existingAnimator.stopAnimation(true)
		case .active:
			existingAnimator.stopAnimation(true)
		case .stopped:
			return animator
		@unknown default:
			print("unknown state switch")
		}


		return animator
	}


	fileprivate func fetchProductDatabaseChanges(_ previousChangeToken: CKServerChangeToken?) {
		//client is responsible for saving the change token at the end of the operation and passing it into the next call to CKFetchDatabaseChangesOperation

		let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousChangeToken)

		operation.fetchAllChanges = true
		operation.resultsLimit = 20
		operation.fetchDatabaseChangesCompletionBlock = { (changeToken, moreComing, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else if let changeToken = changeToken {
					print("database changes fetched")

				}
			}
		}

		operation.changeTokenUpdatedBlock = { changeToken in
			DispatchQueue.main.async {
				print("database change token value updated through changeToken completionblock; new: \(changeToken.debugDescription)")
				self.inventoryDatabaseChangeToken = changeToken
			}
		}

		operation.recordZoneWithIDChangedBlock = { zoneID in
			DispatchQueue.main.async {
				print("\(zoneID.debugDescription) ID of zone was changed")
			}
		}

		let config = CKFetchDatabaseChangesOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10
		operation.configuration = config

		privateDatabase.add(operation)

	}



	func updateForCommit(progress: CGFloat) {
		self.viewPropertyAnimator.fractionComplete = progress
	}

	func completeCommit() {
		UIView.animate(withDuration: 0.15) {
			self.viewPropertyAnimator.fractionComplete = 1
			
		}
	}


	fileprivate func setupInventoryCollectionView() {
		//assign collection delegates and datasource
		self.productsCollectionView.delegate = self
		self.productsCollectionView.dataSource = self
	}

	fileprivate func setupAddButtonForViewController() {
		//add button work here
		self.addProductButton.addButtonDelegate = self

		//haptic setup for button here
		self.addProductButton.addTarget(self, action: #selector(handleHapticsForAddButton(sender:)), for: [.backToAnchorPoint, .overEligibleContainerRegion])

		//setting position and size in this vc
		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))
		originalAddButtonSize = addProductButton.bounds.size

		//setup pan gesture
		setupAddButtonPanGesture(button: self.addProductButton)


	}

	fileprivate func setupPeekAndPopForInventoryCollection() {
		//previewInteraction setup
		self.definesPresentationContext = true
		registerForPreviewing(with: self, sourceView: productsCollectionView)
		print("registered for previewing")
	}

	fileprivate func setupAnimatorForButtonPreviewInteraction() {
		viewPropertyAnimator.pausesOnCompletion = false
		viewPropertyAnimator.isInterruptible = true
		viewPropertyAnimator.scrubsLinearly = true
		viewPropertyAnimator.addAnimations {

			print("added button to container stack view")
			self.containerOptionsView.addSubview(self.addProductButton)
			self.containerOptionsView.alpha = 1.0
		}
		viewPropertyAnimator.addCompletion { (animatingPosition) in
			self.view.addSubview(self.addProductButton)
			self.containerOptionsView.layoutSubviews()
		}
	}

	fileprivate func setupAnimatorForProductChangeConfirmation() {
		productChangeConfirmationAnimator = UIViewPropertyAnimator(duration: 2, curve: .easeInOut)
		productChangeConfirmationAnimator.isInterruptible = true
		productChangeConfirmationAnimator.isUserInteractionEnabled = false
		productChangeConfirmationAnimator.startAnimation()
//		productChangeConfirmationAnimator.pausesOnCompletion = false
	}

	fileprivate func setupDynamicAnimator() {
		//dynamic animator work
		dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
		dynamicAnimator.delegate = self
		snapBehavior = UISnapBehavior(item: addProductButton, snapTo: originalAddButtonPosition)
		snapBehavior.damping = 0.8
		dynamicAnimator.addBehavior(snapBehavior)
	}

}

//!!MARK -- Objc methods

extension InventoryViewController {

	@objc func handleNotificationForInventoryChanges() {
//		CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope) {
//			print("fetch changes from notification observer in inventory view finished")
//			DispatchQueue.main.async {
//				self.updateInventoryCollectionView()
//			}
//		}
		DispatchQueue.main.async {
			print("handling notification and updating collection view")
			self.updateInventoryCollectionView()
		}

	}







	@objc func handlePanForAddButton(recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let translation = recognizer.translation(in: self.view)
		if dynamicAnimator.isRunning {
			return
		}

		switch recognizer.state {
		case .changed:
			addProductButton.center = CGPoint(x: addProductButton.center.x + translation.x, y: addProductButton.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)

			handleGestureChanged(gesture: recognizer)
			guard let indexPath = self.productsCollectionView.indexPathForItem(at: location), let cell = self.productsCollectionView.cellForItem(at: indexPath) else {
				print("no cell)")
				return
			}
			addProductButton.sendActions(for: .overEligibleContainerRegion)
			print("collision with \(cell.debugDescription)")
		case .began:
			recognizer.setTranslation(.zero, in: view)

			dynamicAnimator.removeBehavior(snapBehavior)

			addProductButton.center = location

		case .ended:
			recognizer.setTranslation(.zero, in: view)

			handleGestureEnded(gesture: recognizer)

			guard let indexPath = self.productsCollectionView.indexPathForItem(at: location), let cell = self.productsCollectionView.cellForItem(at: indexPath) as? InventoryCollectionViewCell else {
				print("no cell to segue to product from, pulling button back t position")
				self.viewPropertyAnimator.fractionComplete = 0
				if self.addProductButton.superview != view {	self.view.addSubview(self.addProductButton)
				}
				snapAddButtonToInitialPosition(button: addProductButton, animator: addProductButton.propertyAnimator, dynamicAnimator: dynamicAnimator)
				return
			}
			performSegue(withIdentifier: "ProductDetailSegue", sender: cell)

			//whole lot has to be implemented here
			//have to handle checking to see if the location passes a hit test for any appropriate views in the view hierarchy

		case .cancelled, .failed:
			recognizer.setTranslation(.zero, in: view)

			dynamicAnimator.addBehavior(snapBehavior)


		case .possible:
			print("possible pan gesture state case. No implementation")
		@unknown default:
			fatalError("unknown default handling of unknown case in switch: InventoryViewController.swift")
		}

	}

	func handleGestureChanged(gesture: UIGestureRecognizer) {
		let pressedLocation = gesture.location(in: self.containerOptionsView)
		let hitTestView = containerOptionsView.hitTest(pressedLocation, with: nil)
		if hitTestView is UIImageView {
			UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {

				guard let stackView = self.containerOptionsView.subviews.first as? UIStackView else { return }
				stackView.subviews.forEach({ (imageView) in
					imageView.transform = .identity
				})
				hitTestView?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

			}, completion: nil)
		}
	}

	func handleGestureEnded(gesture: UIGestureRecognizer) {
		let pressedLocation = gesture.location(in: self.containerOptionsView)
		let hitTestView = containerOptionsView.hitTest(pressedLocation, with: nil)
		guard let hitOption = hitTestView as? UIImageView else {
			print("ended on a hit view that is not image view. returning")
			return
		}
		switch hitOption.tag {
		case 1:
			self.addProductButton.setImage(nil, for: .normal)
			self.addProductButton.setImage(nil, for: .disabled)
			self.addProductButton.setImage(nil, for: .focused)
			self.addProductButton.setImage(nil, for: .application)
			self.addProductButton.setImage(nil, for: .highlighted)
			self.addProductButton.setImage(nil, for: .reserved)
			self.addProductButton.setImage(nil, for: .selected)
			self.addProductButton.setTitle("+", for: .normal)
			self.addProductButton.setTitle("+", for: .disabled)
			self.addProductButton.setTitle("+", for: .focused)
			self.addProductButton.setTitle("+", for: .application)
			self.addProductButton.setTitle("+", for: .highlighted)
			self.addProductButton.setTitle("+", for: .reserved)
			self.addProductButton.setTitle("+", for: .selected)
			print("ended over add option")
		case 2:
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .normal)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .disabled)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .focused)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .application)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .highlighted)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .reserved)
			self.addProductButton.setImage(#imageLiteral(resourceName: "deleteButtonImage"), for: .selected)
			self.addProductButton.setTitle(nil, for: .normal)
			self.addProductButton.setTitle(nil, for: .disabled)
			self.addProductButton.setTitle(nil, for: .focused)
			self.addProductButton.setTitle(nil, for: .application)
			self.addProductButton.setTitle(nil, for: .highlighted)
			self.addProductButton.setTitle(nil, for: .reserved)
			self.addProductButton.setTitle(nil, for: .selected)
			print("ended over delete option")
		default:
			break
		}



	}

	@objc func handleHapticsForAddButton(sender: AddProductFloatingButton) {


		let targets = sender.allControlEvents
		switch targets {
		case .backToAnchorPoint:
			print("back to anchor point haptic action triggered")
			sender.generator.impactOccurred()
		case .overEligibleContainerRegion:
			print("over eligible container region haptic action")
			sender.generator.impactOccurred()
		default:
			sender.generator.impactOccurred()
			print("do nothing")
		}


	}




}



extension InventoryViewController: InventoryFilterDelegate {
	func filterInventory(using filterOption: FilterOption) {

		guard var masterInventory = masterProductArray else { return }

		self.inventoryFilterOption = filterOption
		switch filterOption {

		case .dateOpened:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.dateOpened != nil
			})
			self.currentInventory?.sort(by: { (productOne, productTwo) -> Bool in
				return productOne.dateOpened! < productTwo.dateOpened!
			})
			filterButton?.tintColor = .red
			print("sorting by date Opened")
		case .lastDoseTime:
			//				self.currentInventory?.filter(<#T##isIncluded: (Product) throws -> Bool##(Product) throws -> Bool#>)
			print("not implemented")
		case .massRemaining:
			masterInventory.sort(by: { (productOne, productTwo) -> Bool in
				return productOne.mass < productTwo.mass
			})
			self.currentInventory = masterInventory

			filterButton?.tintColor = .red
			print("filtering based on remaining mass")
		case .numberOfDoses:
			self.currentInventory = masterInventory.sorted { (productOne, productTwo) -> Bool in
				return productOne.numberOfDosesTakenFromProduct < productTwo.numberOfDosesTakenFromProduct
			}

			filterButton?.tintColor = .red
			print("Sorting based on Number of Doses")
		case .openedStatus:

			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				guard let _ = someProduct.dateOpened else { return false }
				return true
			})

			filterButton?.tintColor = .red
			print("filtered based on open status")
		case .strainVarietyIndica:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .indica
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .strainVarietySativa:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .sativa
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .strainVarietyHybrid:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .hybrid
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .none:
			self.currentInventory = masterInventory

			filterButton?.tintColor = .blue
			print("Filtering with None")

		}


	}



}



extension InventoryViewController: EditMassDelegate {


	func editMassForProduct(product: Product, with record: CKRecord.ID) {
		DispatchQueue.main.async {
			let massEditView = UIAlertController(title: "Edit Mass \(product.productType.rawValue) \(product.strain.name)", message: "Enter updated mass value in grams", preferredStyle: .alert)
			massEditView.addTextField(configurationHandler: nil)
			let confirmMassEditAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] (_) in
				product.mass = Double(massEditView.textFields?.first!.text ?? "0.0") ?? 0.0
				self.saveChangesToProduct(product: product, record: product.toCKRecord())
			})
			let cancelMassEditAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			massEditView.addAction(confirmMassEditAction)
			massEditView.addAction(cancelMassEditAction)

			self.present(massEditView, animated: true, completion: nil)
		}

	}

	func saveChangesToProduct(product: Product, record: CKRecord) {
		guard let recordValue = product.encodeProductAsCKRecordValue() else { return }

		let manager = FileManager.default
		let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
		let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask

		let paths = manager.urls(for: nsDocumentDirectory, in: nsUserDomainMask)

		if paths.count > 0 {
			let dirPath = paths[0]
			let writePath = dirPath.appendingPathComponent(product.productType.rawValue + product.strain.name + (product.dateOpened?.description(with: .current) ?? "Unopened"))
			let productImage: UIImage = {
				let imageToReturn: UIImage = UIImage(imageLiteralResourceName: "cannaleaf.png")
				guard let image = product.productLabelImage else { return imageToReturn }
				return image
			}()

			try? productImage.pngData()?.write(to: writePath)
			let productImageData: CKAsset? = CKAsset(fileURL: NSURL(fileURLWithPath: writePath.path) as URL)
			record.setObject(productImageData, forKey: "ProductImageData")
		}
		record.setObject(recordValue, forKey: "ProductData")
		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let configuration = CKModifyRecordsOperation.Configuration()
		configuration.timeoutIntervalForResource = 20
		configuration.timeoutIntervalForRequest = 20
		operation.configuration = configuration

		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				self.navigationItem.backBarButtonItem?.isEnabled = true
				if let error = error {
					print(error)
				} else {
					if let savedRecords = savedRecords {
						self.updateInventoryCollectionView()
						print("\(savedRecords) Records were saved")
					}
				}
			}

		}

		privateDatabase.add(operation)


	}


}








extension InventoryViewController: AddButtonDelegate {


	func snapAddButtonToInitialPosition(button: AddProductFloatingButton, animator: UIViewPropertyAnimator, dynamicAnimator: UIDynamicAnimator) {
		dynamicAnimator.removeBehavior(snapBehavior)
		snapBehavior = UISnapBehavior(item: addProductButton, snapTo: originalAddButtonPosition)
		dynamicAnimator.addBehavior(snapBehavior)
	}

	func setupAddButtonPanGesture(button: AddProductFloatingButton) {
		let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForAddButton(recognizer:)))
		addProductButton.addGestureRecognizer(pan)
		addProductButton.isUserInteractionEnabled = true
	}

	func animateTouchesBegan(button: AddProductFloatingButton, animator: UIViewPropertyAnimator) {

	}


}

extension InventoryViewController: InventoryManagerDelegate {
	func addProductToInventory(product: Product) {
		self.masterProductArray?.append(product)
		self.updateInventoryCollectionView()
	}

	func deleteProductFromLocalInventory(product: Product) {
		guard let matchingProductToRemoveIndex = masterProductArray?.firstIndex(of: product) else {
			print("there was no matching product to obtain an index to remove")
			return
		}
		self.masterProductArray?.remove(at: matchingProductToRemoveIndex)
		self.updateInventoryCollectionView()
	}

	func updateProduct(product: Product) {
		guard let matchingProductToUpdateIndexFirst = masterProductArray?.firstIndex(where: { (someProduct) -> Bool in
			return (someProduct.productType == product.productType) && (someProduct.numberOfDosesTakenFromProduct == product.numberOfDosesTakenFromProduct) && (someProduct.recordID == product.recordID)
		}) else { return }
		guard let indexPath = indexPathForUpdateActionCell, let _ = self.productsCollectionView.cellForItem(at: indexPath) as? InventoryCollectionViewCell else {
			print("could not get either cell or indexPAth to update and animate confirmation; returning")
			return
		}
		self.productsCollectionView.performBatchUpdates({
			self.productsCollectionView.reloadItems(at: [indexPathForUpdateActionCell!])
		}) { (didCompleteAnimations) in
			if didCompleteAnimations {
				guard let indexPath = self.indexPathForUpdateActionCell, let cell = self.productsCollectionView.cellForItem(at: indexPath) as? InventoryCollectionViewCell else {
					print("could not get either cell or indexPAth to update and animate confirmation; returning")
					return
				}
//				cell.layoutIfNeeded()
				cell.contentView.bringSubviewToFront(cell.confirmationIndicator ?? UIImageView(image: #imageLiteral(resourceName: "greenCheck")))
//				cell.confirmationIndicator.alpha = 0.0
				self.productChangeConfirmationAnimator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2, delay: 0, options: [], animations: {
					cell.confirmationIndicator.alpha = 1.0
				}, completion: { (_) in
					UIView.animate(withDuration: 2, animations: {
						cell.confirmationIndicator.alpha = 0.0
					})
				})
//				.allowAnimatedContent, .curveEaseInOut, .allowUserInteraction, .beginFromCurrentState, .layoutSubviews
			}
		}




	}

}



extension InventoryViewController: UIDynamicAnimatorDelegate {

	func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {

		guard let button = animator.items(in: self.view.frame).first as? AddProductFloatingButton else {
			print("There is no button; not able to be cast as The Button, anyway")
			return
		}
		self.addProductButton.animateButtonForRegion(for: originalAddButtonSize)
		UIView.animate(withDuration: 0.25) {
			self.addProductButton.alpha = 1
		}

		button.sendActions(for: .backToAnchorPoint)
	}

}


extension InventoryViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = productsCollectionView.indexPathForItem(at: location), let cell = productsCollectionView.cellForItem(at: indexPath) as? InventoryCollectionViewCell, let product = currentInventory?[indexPath.item] else { return nil }
		cellForUpdateAction = cell
		previewingContext.sourceRect = cell.frame

		guard let viewController = storyboard?.instantiateViewController(withIdentifier: "ProductDetailViewController") as? ProductDetailViewController else { return nil }
		viewController.inventoryManagerDelegate = self
		viewController.editMassDelegate = self
		viewController.activeDetailProduct = product

		return viewController
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard let vcAsDetailVC = viewControllerToCommit as? ProductDetailViewController else { return }
		vcAsDetailVC.inventoryManagerDelegate = self
		vcAsDetailVC.editMassDelegate = self
		navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}





}

extension InventoryViewController: UIPreviewInteractionDelegate {
	func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdatePreviewTransition transitionProgress: CGFloat, ended: Bool) {

		addProductButton.updateAnimationProgress(with: transitionProgress)

		if ended {
			addProductButton.completePreview()
//			view.bringSubviewToFront(containerOptionsView)
			self.containerOptionsView.transform = .init(translationX: addProductButton.center.x - (self.containerOptionsView.frame.width / 2), y: addProductButton.center.y - self.containerOptionsView.frame.height)
//			viewPropertyAnimator.stopAnimation()
			viewPropertyAnimator.addAnimations {

				print("added button to container stack view")
				self.containerOptionsView.addSubview(self.addProductButton)
//				self.addProductButton.alpha = 0.5
				self.containerOptionsView.alpha = 1.0
			}

		}

	}

	func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdateCommitTransition transitionProgress: CGFloat, ended: Bool) {
		updateForCommit(progress: transitionProgress)
		if ended {
			completeCommit()
			self.addProductButton.updateAnimationProgress(with: 0.0)
		}
	}

	func previewInteractionDidCancel(_ previewInteraction: UIPreviewInteraction) {
		addProductButton.completePreview()
		viewPropertyAnimator.fractionComplete = 0
	}

	func previewInteractionShouldBegin(_ previewInteraction: UIPreviewInteraction) -> Bool {
//		addProductButton.animateButtonForPreviewInteractionChoice()
		return true
	}



}
