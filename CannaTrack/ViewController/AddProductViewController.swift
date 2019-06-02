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
import CoreML
import VideoToolbox

precedencegroup ForwardPipe {
	associativity: left
	higherThan: LogicalConjunctionPrecedence
}

infix operator |> : ForwardPipe

public func |> <T, U>(value: T, function: ((T) -> U)) -> U {
	return function(value)
}

extension UIImage {
	public convenience init?(pixelBuffer: CVPixelBuffer) {
		var cgImage: CGImage?
		VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
		if let cgImage = cgImage {
			self.init(cgImage: cgImage)
		} else { return nil }
	}
}


class AddProductViewController: UIViewController {

	@IBOutlet var productCategoryScanResultText: UITextView!

	//MARK: -- VISION WORK

	@IBOutlet var scannedProductTextField: UITextView!

	@IBOutlet var productImageToAdd: UIImageView!

	var session = AVCaptureSession()

	var requests = [VNRequest]()

	var model: VNCoreMLModel!

	var textMetadata = [Int: [Int: String]]()

	private func loadModel() {
		model = try? VNCoreMLModel(for: Alphanum_28x28().model)
	}


	var productToAdd: Product?

    var pathLayer: CALayer?

	var imageWidth: CGFloat = 0
	var imageHeight: CGFloat = 0


	override func viewDidLoad() {
        super.viewDidLoad()
		loadModel()
		let photoTap = UITapGestureRecognizer(target: self, action: #selector(promptPhoto))
		self.productImageToAdd.addGestureRecognizer(photoTap)


//		perform(#selector(promptPhoto), with: nil, afterDelay: 0.1)

        // Do any additional setup after loading the view.
    }


	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		startLiveVideo()
		startTextDetection()
	}

	override func viewDidLayoutSubviews() {
		productImageToAdd.layer.sublayers?[0].frame = productImageToAdd.bounds
	}

	@objc func promptPhoto() {
		let imagePicker = UIImagePickerController()
		imagePicker.sourceType = .camera
		imagePicker.allowsEditing = true
		imagePicker.delegate = self

		self.present(imagePicker, animated: true)
	}

	// MARK: - Tesseract Helpers


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
		@unknown default:
			fatalError("Default Unknown case for UIImage Orientations; instantiating crash")
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
//		promptPhoto()
		if session.isRunning {
			session.stopRunning()
			clearOldData()
			detectText(image: productImageToAdd.image!)

		} else {
			session.startRunning()
		}

	}

	@IBAction func scanProductToAddImageForData(_ sender: UIButton) {
//		guard let uiImageForVision = productToAdd?.productLabelImage else { return }
		guard (productToAdd?.productLabelImage?.cgImage) != nil else { return }

//		let imageRequestHandler = VNImageRequestHandler(cgImage: cgImageForVision, orientation: .up, options: [:])

	}


	@IBAction func saveNewProductTapped(_ sender: UIBarButtonItem) {
		guard let product = productToAdd else { return }
		saveProductToInventory(product: product)
	}







}


extension AddProductViewController {

	func refreshUI() {
		guard let image = productToAdd?.productLabelImage else { return }
		productImageToAdd.image = image
	}
}


//MARK: -- AV Methods
extension AddProductViewController {
	func startLiveVideo() {
		//1
		session.sessionPreset = AVCaptureSession.Preset.photo
		let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)

		//2
		let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
		let deviceOutput = AVCaptureVideoDataOutput()
		deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
		deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
		session.addInput(deviceInput)
		session.addOutput(deviceOutput)

		//3
		let imageLayer = AVCaptureVideoPreviewLayer(session: session)
		imageLayer.frame = productImageToAdd.bounds
		productImageToAdd.layer.addSublayer(imageLayer)

		session.startRunning()
	}

	

	func startTextDetection() {
		let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
		textRequest.reportCharacterBoxes = true
		self.requests = [textRequest]
	}

	func detectTextHandler(request: VNRequest, error: Error?) {
		guard let observations = request.results else {
			print("no result")
			return
		}

		let result = observations.map({$0 as? VNTextObservation})

		if result.count == 0 {
			self.handleEmptyResults()
			return
		}

		DispatchQueue.main.async {
			self.productImageToAdd.layer.sublayers?.removeSubrange(1...)
			var numberOfWords = 0
			for region in result {
				guard let rg = region else {
					continue
				}

				self.highlightWord(box: rg)
				var numberOfCharacters = 0
				if let boxes = region?.characterBoxes {
					for box in boxes {
						//highlight letters
						self.highlightLetters(box: box)

					}
				}
				numberOfWords += 1
			}

		}
	}

	// MARK: text detection

	func detectText(image: UIImage) {
		let convertedImage = image |> adjustColors |> convertToGrayscale
		let correctedImage = createMatchingBackingDataWithImage(imageRef: convertedImage.cgImage, orienation: .up)
		let handler = VNImageRequestHandler(cgImage: correctedImage!)
		let request: VNDetectTextRectanglesRequest =
			VNDetectTextRectanglesRequest(completionHandler: { [unowned self] (request, error) in
				if (error != nil) {
					print("Got Error In Run Text Dectect Request :(")
				} else {
					guard let results = request.results as? Array<VNTextObservation> else {
						fatalError("Unexpected result type from VNDetectTextRectanglesRequest")
					}
					if (results.count == 0) {
						self.handleEmptyResults()
						return
					}
					var numberOfWords = 0
					for textObservation in results {
						var numberOfCharacters = 0
						for rectangleObservation in textObservation.characterBoxes! {
							let croppedImage = crop(image: image, rectangle: rectangleObservation)
							if let croppedImage = croppedImage {
								let processedImage = preProcess(image: croppedImage)
								self.classifyImage(image: processedImage,
												   wordNumber: numberOfWords,
												   characterNumber: numberOfCharacters)
								numberOfCharacters += 1
							}
						}
						numberOfWords += 1
					}
				}
			})
		request.reportCharacterBoxes = true
		do {
			try handler.perform([request])
		} catch {
			print(error)
		}
	}


	func highlightWord(box: VNTextObservation) {
		guard let boxes = box.characterBoxes else {
			return
		}

		var maxX: CGFloat = 9999.0
		var minX: CGFloat = 0.0
		var maxY: CGFloat = 9999.0
		var minY: CGFloat = 0.0

		for char in boxes {
			if char.bottomLeft.x < maxX {
				maxX = char.bottomLeft.x
			}
			if char.bottomRight.x > minX {
				minX = char.bottomRight.x
			}
			if char.bottomRight.y < maxY {
				maxY = char.bottomRight.y
			}
			if char.topRight.y > minY {
				minY = char.topRight.y
			}
		}

		let xCord = maxX * productImageToAdd.frame.size.width
		let yCord = (1 - minY) * productImageToAdd.frame.size.height
		let width = (minX - maxX) * productImageToAdd.frame.size.width
		let height = (minY - maxY) * productImageToAdd.frame.size.height

		let outline = CALayer()
		outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
		outline.borderWidth = 2.0
		outline.borderColor = UIColor.red.cgColor

		productImageToAdd.layer.addSublayer(outline)
	}

	func highlightLetters(box: VNRectangleObservation) {
		let xCord = box.topLeft.x * productImageToAdd.frame.size.width
		let yCord = (1 - box.topLeft.y) * productImageToAdd.frame.size.height
		let width = (box.topRight.x - box.bottomLeft.x) * productImageToAdd.frame.size.width
		let height = (box.topLeft.y - box.bottomLeft.y) * productImageToAdd.frame.size.height

		let outline = CALayer()
		outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
		outline.borderWidth = 1.0
		outline.borderColor = UIColor.blue.cgColor

		productImageToAdd.layer.addSublayer(outline)
	}


	func handleEmptyResults() {
		DispatchQueue.main.async {
			self.scannedProductTextField.text = "The image does not contain any text"
		}
	}

	private func clearOldData() {
		scannedProductTextField.text = ""
		textMetadata = [:]
	}

	func classifyImage(image: UIImage, wordNumber: Int, characterNumber: Int) {
		let request = VNCoreMLRequest(model: model) { (request, error) in
			guard let results = request.results as? [VNClassificationObservation],
				let topResult = results.first else {
				fatalError("Unexpected result type from VNCoreMLRequest")
			}
			let result = topResult.identifier
			let classificationInfo: [String: Any] = ["wordNumber": wordNumber,
													 "characterNumber": characterNumber,
													 "class": result]
			self.handleResult(classificationInfo)
		}
		guard let ciImage = CIImage(image: image) else { fatalError("could not convert uiimage to ciimage")}
		let handler = VNImageRequestHandler(ciImage: ciImage)
		DispatchQueue.global(qos: .userInteractive).async {
			do {
				try handler.perform([request])
			} catch {
				print(error)
			}
		}
	}

	func handleResult(_ result: [String: Any]) {
		objc_sync_enter(self)

		guard let wordNumber = result["wordNumber"] as? Int else {
			return
		}
		guard let characterNumber = result["characterNumber"] as? Int else {
			return
		}
		guard let characterClass = result["class"] as? String else {
			return
		}

		if (textMetadata[wordNumber] == nil) {
			let tmp: [Int: String] = [characterNumber: characterClass]
			textMetadata[wordNumber] = tmp
		} else {
			var tmp = textMetadata[wordNumber]!
			tmp[characterNumber] = characterClass
			textMetadata[wordNumber] = tmp
		}
		objc_sync_exit(self)
		DispatchQueue.main.async {
			self.showDetectedText()
		}

	}

	func showDetectedText() {
		var result: String = ""
		if (textMetadata.isEmpty) {
			scannedProductTextField.text = "The image does not contain any text"
			return
		}
		let sortedKeys = textMetadata.keys.sorted()
		for sortedKey in sortedKeys {
			result += word(fromDictionary: textMetadata[sortedKey]!) + " "
		}
		scannedProductTextField.text = result
	}


	func word(fromDictionary dictionary: [Int: String]) -> String {
		let sortedKeys = dictionary.keys.sorted()
		var word: String = ""
		for sortedKey in sortedKeys {
			let char: String = dictionary[sortedKey]!
			word += char
		}
		return word
	}
}


extension AddProductViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return
		}
		guard let image = UIImage(pixelBuffer: pixelBuffer) else { return }
		guard let cgImage = image.cgImage else { return }
		guard let correctedCGImage = createMatchingBackingDataWithImage(imageRef: cgImage, orienation: .up) else { return }
		DispatchQueue.main.async {
			self.productImageToAdd.image = UIImage(cgImage: correctedCGImage)
		}
		var requestOptions:[VNImageOption : Any] = [:]

		if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
			requestOptions = [.cameraIntrinsics:camData]
		}

		let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6) ?? .up, options: requestOptions)

		do {
			try imageRequestHandler.perform(self.requests)
		} catch {
			print(error)
		}

	}



}



extension AddProductViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

		self.productToAdd?.currentProductImage = originalImage
		self.productToAdd?.productLabelImage = originalImage

		dismiss(animated: true, completion: nil)

	}

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
