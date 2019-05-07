//
//  AddProductViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/25/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import Vision
import AVKit


class AddProductViewController: UIViewController {

	@IBOutlet var productCategoryScanResultText: UITextView!


	@IBOutlet var scannedProductTextField: UITextView!

	@IBOutlet var productImageToAdd: UIImageView!

	var productToAdd: Product?

    var pathLayer: CALayer?

	var imageWidth: CGFloat = 0
	var imageHeight: CGFloat = 0


	override func viewDidLoad() {
        super.viewDidLoad()

		let photoTap = UITapGestureRecognizer(target: self, action: #selector(promptPhoto))
		self.productImageToAdd.addGestureRecognizer(photoTap)


//		perform(#selector(promptPhoto), with: nil, afterDelay: 0.1)

        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if productImageToAdd.image == nil {
			promptPhoto()
		}
	}

	@objc func promptPhoto() {
		let imagePicker = UIImagePickerController()
		imagePicker.sourceType = .camera
		imagePicker.allowsEditing = true
		imagePicker.delegate = self

		self.present(imagePicker, animated: true)
	}

	// MARK: - Tesseract Helpers
//	func progressImageRecognition(for tesseract: G8Tesseract!) {
//		print("Recognition progress for image \(tesseract.progress)")
//	}

	// MARK: - Helper Methods

	/// - Tag: PreprocessImage
	func scaleAndOrient(image: UIImage) -> UIImage {

		// Set a default value for limiting image size.
		let maxResolution: CGFloat = 640

		guard let cgImage = image.cgImage else {
			print("UIImage has no CGImage backing it!")
			return image
		}

		// Compute parameters for transform.
		let width = CGFloat(cgImage.width)
		let height = CGFloat(cgImage.height)
		var transform = CGAffineTransform.identity

		var bounds = CGRect(x: 0, y: 0, width: width, height: height)

		if width > maxResolution ||
			height > maxResolution {
			let ratio = width / height
			if width > height {
				bounds.size.width = maxResolution
				bounds.size.height = round(maxResolution / ratio)
			} else {
				bounds.size.width = round(maxResolution * ratio)
				bounds.size.height = maxResolution
			}
		}

		let scaleRatio = bounds.size.width / width
		let orientation = image.imageOrientation
		switch orientation {
		case .up:
			transform = .identity
		case .down:
			transform = CGAffineTransform(translationX: width, y: height).rotated(by: .pi)
		case .left:
			let boundsHeight = bounds.size.height
			bounds.size.height = bounds.size.width
			bounds.size.width = boundsHeight
			transform = CGAffineTransform(translationX: 0, y: width).rotated(by: 3.0 * .pi / 2.0)
		case .right:
			let boundsHeight = bounds.size.height
			bounds.size.height = bounds.size.width
			bounds.size.width = boundsHeight
			transform = CGAffineTransform(translationX: height, y: 0).rotated(by: .pi / 2.0)
		case .upMirrored:
			transform = CGAffineTransform(translationX: width, y: 0).scaledBy(x: -1, y: 1)
		case .downMirrored:
			transform = CGAffineTransform(translationX: 0, y: height).scaledBy(x: 1, y: -1)
		case .leftMirrored:
			let boundsHeight = bounds.size.height
			bounds.size.height = bounds.size.width
			bounds.size.width = boundsHeight
			transform = CGAffineTransform(translationX: height, y: width).scaledBy(x: -1, y: 1).rotated(by: 3.0 * .pi / 2.0)
		case .rightMirrored:
			let boundsHeight = bounds.size.height
			bounds.size.height = bounds.size.width
			bounds.size.width = boundsHeight
			transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: .pi / 2.0)
		}

		return UIGraphicsImageRenderer(size: bounds.size).image { rendererContext in
			let context = rendererContext.cgContext

			if orientation == .right || orientation == .left {
				context.scaleBy(x: -scaleRatio, y: scaleRatio)
				context.translateBy(x: -height, y: 0)
			} else {
				context.scaleBy(x: scaleRatio, y: -scaleRatio)
				context.translateBy(x: 0, y: -height)
			}
			context.concatenate(transform)
			context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
		}
	}

	/// - Tag: ConfigureCompletionHandler
	lazy var rectangleDetectionRequest: VNDetectRectanglesRequest = {
		let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
		// Customize & configure the request to detect only certain rectangles.
		rectDetectRequest.maximumObservations = 8 // Vision currently supports up to 16.
		rectDetectRequest.minimumConfidence = 0.6 // Be confident.
		rectDetectRequest.minimumAspectRatio = 0.3 // height / width
		return rectDetectRequest
	}()

	lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
		let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleDetectedText)
		// Tell Vision to report bounding box around each character.
		textDetectRequest.reportCharacterBoxes = true
		return textDetectRequest
	}()

	lazy var barcodeDetectionRequest: VNDetectBarcodesRequest = {
		let barcodeDetectRequest = VNDetectBarcodesRequest(completionHandler: self.handleDetectedBarcodes)
		// Restrict detection to most common symbologies.
		barcodeDetectRequest.symbologies = [.QR, .Aztec, .UPCE]
		return barcodeDetectRequest
	}()


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

	@IBAction func unwindToInventoryCollection(unwindSegue: UIStoryboardSegue) {

	}

	@IBAction func scanToAddProductTapped(_ sender: Any) {
		promptPhoto()
	}

	@IBAction func scanProductToAddImageForData(_ sender: UIButton) {
//		guard let uiImageForVision = productToAdd?.productLabelImage else { return }
		guard let cgImageForVision = productToAdd?.productLabelImage?.cgImage else { return }

//		let imageRequestHandler = VNImageRequestHandler(cgImage: cgImageForVision, orientation: .up, options: [:])

	}


	@IBAction func saveNewProductTapped(_ sender: UIBarButtonItem) {
		guard let product = productToAdd else { return }
		saveProductToInventory(product: product)
	}

	@IBAction func addNewProductToInventory(_ sender: Any) {
		guard let product = productToAdd else { return }
		saveProductToInventory(product: product)
	}





}


extension AddProductViewController {

	func refreshUI() {
		guard let image = productToAdd?.currentProductImage else { return }
		productImageToAdd.image = image
	}



}

extension AddProductViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

//		if let tesseract = G8Tesseract(language: "eng") {
//			tesseract.engineMode = .tesseractOnly
//			tesseract.delegate = self
//			tesseract.image = originalImage.g8_blackAndWhite()
//			tesseract.recognize()
//
//			self.productImageToAdd.image = originalImage
//			self.scannedProductTextField.text = tesseract.recognizedText
//			if tesseract.recognizedText.lowercased().contains("trushatter") {
//				self.productCategoryScanResultText.text = "truShatter"
//				self.productToAdd = Product(typeOfProduct: .truShatter, strainForProduct: Strain(id: 2, name: "no", race: .hybrid, description: "no"), inGrams: 1.0)
//			} else if tesseract.recognizedText.lowercased().contains("truflower") {
//				self.productCategoryScanResultText.text = "truFlower"
//				self.productToAdd = Product(typeOfProduct: .truFlower, strainForProduct: Strain(id: 2, name: "no", race: .hybrid, description: "no"), inGrams: 1.0)
//			} else if tesseract.recognizedText.lowercased().contains("trucrmbl") {
//				self.productCategoryScanResultText.text = "truCRMBL"
//				self.productToAdd = Product(typeOfProduct: .truCrmbl, strainForProduct: Strain(id: 2, name: "no", race: .hybrid, description: "no"), inGrams: 1.0)
//			} else if tesseract.recognizedText.lowercased().contains("truclear") {
//				self.productCategoryScanResultText.text = "truClear"
//				self.productToAdd = Product(typeOfProduct: .truClear, strainForProduct: Strain(id: 2, name: "no", race: .hybrid, description: "no"), inGrams: 1.0)
//			}
//
//		} else { print("not able to instantiate tesseract") }


		self.productToAdd?.currentProductImage = originalImage
		self.productToAdd?.productLabelImage = originalImage

		dismiss(animated: true, completion: nil)

	}


	func show(_ image: UIImage) {

		// Remove previous paths & image
		pathLayer?.removeFromSuperlayer()
		pathLayer = nil
		productImageToAdd.image = nil

		// Account for image orientation by transforming view.
		let correctedImage = scaleAndOrient(image: image)

		// Place photo inside imageView.
		productImageToAdd.image = correctedImage

		// Transform image to fit screen.
		guard let cgImage = correctedImage.cgImage else {
			print("Trying to show an image not backed by CGImage!")
			return
		}

		let fullImageWidth = CGFloat(cgImage.width)
		let fullImageHeight = CGFloat(cgImage.height)

		let imageFrame = productImageToAdd.frame
		let widthRatio = fullImageWidth / imageFrame.width
		let heightRatio = fullImageHeight / imageFrame.height

		// ScaleAspectFit: The image will be scaled down according to the stricter dimension.
		let scaleDownRatio = max(widthRatio, heightRatio)

		// Cache image dimensions to reference when drawing CALayer paths.
		imageWidth = fullImageWidth / scaleDownRatio
		imageHeight = fullImageHeight / scaleDownRatio

		// Prepare pathLayer to hold Vision results.
		let xLayer = (imageFrame.width - imageWidth) / 2
		let yLayer = productImageToAdd.frame.minY + (imageFrame.height - imageHeight) / 2
		let drawingLayer = CALayer()
		drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
		drawingLayer.anchorPoint = CGPoint.zero
		drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
		drawingLayer.opacity = 0.5
		pathLayer = drawingLayer
		self.view.layer.addSublayer(pathLayer!)
	}

}

extension AddProductViewController: AVCaptureVideoDataOutputSampleBufferDelegate {



}



extension AddProductViewController {

	func presentAlert(_ title: String, error: NSError) {
		// Always present alert on main thread.
		DispatchQueue.main.async {
			let alertController = UIAlertController(title: title,
													message: error.localizedDescription,
													preferredStyle: .alert)
			let okAction = UIAlertAction(title: "OK",
										 style: .default) { _ in
											// Do nothing -- simply dismiss alert.
			}
			alertController.addAction(okAction)
			self.present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Vision

	/// - Tag: PerformRequests
	fileprivate func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {

		// Fetch desired requests based on switch status.
		let requests = createVisionRequests()
		// Create a request handler.
		let imageRequestHandler = VNImageRequestHandler(cgImage: image,
														orientation: orientation,
														options: [:])

		// Send the requests to the request handler.
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try imageRequestHandler.perform(requests)
			} catch let error as NSError {
				print("Failed to perform image request: \(error)")
//				self.presentAlert("Image Request Failed", error: error)
				return
			}
		}
	}

	/// - Tag: CreateRequests
	fileprivate func createVisionRequests() -> [VNRequest] {

		// Create an array to collect all desired requests.
		var requests: [VNRequest] = []

//		requests.append(self.rectangleDetectionRequest)
		requests.append(self.textDetectionRequest)
		// Return grouped requests as a single array.
		return requests
	}

	fileprivate func handleDetectedRectangles(request: VNRequest?, error: Error?) {
		if let nsError = error as NSError? {
			self.presentAlert("Rectangle Detection Error", error: nsError)
			return
		}
		// Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
		DispatchQueue.main.async {
			guard let drawLayer = self.pathLayer,
				let results = request?.results as? [VNRectangleObservation] else {
					return
			}
			self.draw(rectangles: results, onImageWithBounds: drawLayer.bounds)
			drawLayer.setNeedsDisplay()
		}
	}


	fileprivate func handleDetectedText(request: VNRequest?, error: Error?) {
		if let nsError = error as NSError? {
			self.presentAlert("Text Detection Error", error: nsError)
			return
		}
		// Perform drawing on the main thread.
		DispatchQueue.main.async {
			guard let drawLayer = self.pathLayer,
				let results = request?.results as? [VNTextObservation] else {
					return
			}
			self.draw(text: results, onImageWithBounds: drawLayer.bounds)
			drawLayer.setNeedsDisplay()
		}
	}

	fileprivate func handleDetectedBarcodes(request: VNRequest?, error: Error?) {
		if let nsError = error as NSError? {
			self.presentAlert("Barcode Detection Error", error: nsError)
			return
		}
		// Perform drawing on the main thread.
		DispatchQueue.main.async {
			guard let drawLayer = self.pathLayer,
				let results = request?.results as? [VNBarcodeObservation] else {
					return
			}
			self.draw(barcodes: results, onImageWithBounds: drawLayer.bounds)
			drawLayer.setNeedsDisplay()
		}
	}

	// MARK: - Path-Drawing

	fileprivate func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {

		let imageWidth = bounds.width
		let imageHeight = bounds.height

		// Begin with input rect.
		var rect = forRegionOfInterest

		// Reposition origin.
		rect.origin.x *= imageWidth
		rect.origin.x += bounds.origin.x
		rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y

		// Rescale normalized coordinates.
		rect.size.width *= imageWidth
		rect.size.height *= imageHeight

		return rect
	}

	fileprivate func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
		// Create a new layer.
		let layer = CAShapeLayer()

		// Configure layer's appearance.
		layer.fillColor = nil // No fill to show boxed object
		layer.shadowOpacity = 0
		layer.shadowRadius = 0
		layer.borderWidth = 2

		// Vary the line color according to input.
		layer.borderColor = color.cgColor

		// Locate the layer.
		layer.anchorPoint = .zero
		layer.frame = frame
		layer.masksToBounds = true

		// Transform the layer to have same coordinate system as the imageView underneath it.
		layer.transform = CATransform3DMakeScale(1, -1, 1)

		return layer
	}

	// Rectangles are BLUE.
	fileprivate func draw(rectangles: [VNRectangleObservation], onImageWithBounds bounds: CGRect) {
		CATransaction.begin()
		for observation in rectangles {
			let rectBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
			let rectLayer = shapeLayer(color: .blue, frame: rectBox)

			// Add to pathLayer on top of image.
			pathLayer?.addSublayer(rectLayer)
		}
		CATransaction.commit()
	}

	// Faces are YELLOW.
	/// - Tag: DrawBoundingBox
	fileprivate func draw(faces: [VNFaceObservation], onImageWithBounds bounds: CGRect) {
		CATransaction.begin()
		for observation in faces {
			let faceBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
			let faceLayer = shapeLayer(color: .yellow, frame: faceBox)

			// Add to pathLayer on top of image.
			pathLayer?.addSublayer(faceLayer)
		}
		CATransaction.commit()
	}



	// Lines of text are RED.  Individual characters are PURPLE.
	fileprivate func draw(text: [VNTextObservation], onImageWithBounds bounds: CGRect) {
		CATransaction.begin()
		for wordObservation in text {
			let wordBox = boundingBox(forRegionOfInterest: wordObservation.boundingBox, withinImageBounds: bounds)
			let wordLayer = shapeLayer(color: .red, frame: wordBox)

			// Add to pathLayer on top of image.
			pathLayer?.addSublayer(wordLayer)

			// Iterate through each character within the word and draw its box.
			guard let charBoxes = wordObservation.characterBoxes else {
				continue
			}
			for charObservation in charBoxes {
				let charBox = boundingBox(forRegionOfInterest: charObservation.boundingBox, withinImageBounds: bounds)
				let charLayer = shapeLayer(color: .purple, frame: charBox)
				charLayer.borderWidth = 1

				// Add to pathLayer on top of image.
				pathLayer?.addSublayer(charLayer)
			}
		}
		CATransaction.commit()
	}

	// Barcodes are ORANGE.
	fileprivate func draw(barcodes: [VNBarcodeObservation], onImageWithBounds bounds: CGRect) {
		CATransaction.begin()
		for observation in barcodes {
			let barcodeBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
			let barcodeLayer = shapeLayer(color: .orange, frame: barcodeBox)

			// Add to pathLayer on top of image.
			pathLayer?.addSublayer(barcodeLayer)
		}
		CATransaction.commit()
	}

}


extension CGMutablePath {
	// Helper function to add lines to a path.
	func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D,
				   applying affineTransform: CGAffineTransform,
				   closingWhenComplete closePath: Bool) {
		let pointCount = landmarkRegion.pointCount

		// Draw line if and only if path contains multiple points.
		guard pointCount > 1 else {
			return
		}
		self.addLines(between: landmarkRegion.normalizedPoints, transform: affineTransform)

		if closePath {
			self.closeSubpath()
		}
	}
}

extension CGImagePropertyOrientation {
	init(_ uiImageOrientation: UIImage.Orientation) {
		switch uiImageOrientation {
		case .up: self = .up
		case .down: self = .down
		case .left: self = .left
		case .right: self = .right
		case .upMirrored: self = .upMirrored
		case .downMirrored: self = .downMirrored
		case .leftMirrored: self = .leftMirrored
		case .rightMirrored: self = .rightMirrored
		}
	}
}
