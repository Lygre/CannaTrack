import UIKit
import CloudKit
import PlaygroundSupport


var str = "Hello, playground"

let startDate = Date()

let formatter = DateFormatter()

formatter.locale = .current
formatter.timeZone = .current
formatter.calendar = .current

formatter.dateFormat = "yyy-MM-dd"
var dateString = "2016-03-02"


var date = formatter.date(from: dateString)

let userCalendar = Calendar.current

let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]

let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: startDate)
dateTimeComponents.year
dateTimeComponents.month
dateTimeComponents.day

let dictionaryEntry = String(dateTimeComponents.year!) + String(dateTimeComponents.month!) + String(dateTimeComponents.day!)
var dateComponents = DateComponents()
dateComponents.year = dateTimeComponents.year
dateComponents.month = dateTimeComponents.month
dateComponents.day = dateTimeComponents.day

let someDateTime = userCalendar.date(from: dateComponents)

func saveUserData(with dataToWrite: [String]) {
	let propertyListEncoder = PropertyListEncoder()
	do {
		let data = try propertyListEncoder.encode(dataToWrite)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}

func loadProductInventoryFromUserData() -> [String] {
	let propertyListDecoder = PropertyListDecoder()
	var storedData: [String] = []
	do {
		if let da = UserDefaults.standard.data(forKey: "data") {
			let stored = try propertyListDecoder.decode([String].self, from: da)
			storedData = stored
		}
	}
	catch {
		print(error)
	}
	return storedData
}

func saveUserDataTextField(with dataToWriteFromTextField: String) {
	let propertyListEncoder = PropertyListEncoder()
	var savedData: [String] = loadProductInventoryFromUserData()

	savedData.append(dataToWriteFromTextField)

	do {
		let data = try propertyListEncoder.encode(savedData)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}

let dates: [Date] = [Date(), Date(timeIntervalSinceReferenceDate: TimeInterval(exactly: 8.0)!)]
dates.sorted { (date, otherDate) -> Bool in
	return date > otherDate
}

//-----------------------------------

var array: [Int] = []

class ViewController: UIViewController {

	var array: [Int]? {
		willSet(oldArray) {
			print(oldArray)
		}
	}

	var animator: UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 3, curve: .easeInOut) {
		willSet {
			print(newValue)
		}
		didSet {
			print(self.animator)
		}
	}

	var madeView: UIView!

	private func makeView() -> UIView {
		let madeView = UIView()
		madeView.frame = CGRect(origin: .zero, size: CGSize(width: 120, height: 120))
		madeView.backgroundColor = .green
		madeView.layer.masksToBounds = true
		madeView.layer.cornerRadius = madeView.bounds.width / 2.0
		return madeView
	}

	var property: String?

	init(with array: [Int]?) {
		super.init(nibName: nil, bundle: Bundle.main)
		self.array = array
		self.view.backgroundColor = .yellow
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		madeView = makeView()
		view.addSubview(madeView)
		madeView.alpha = 0.0
		let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
		madeView.addGestureRecognizer(tap)
		//		animator
		animator.startAnimation()

		let tapView = UITapGestureRecognizer(target: self, action: #selector(handleTapOnView(recognizer:)))
		view.addGestureRecognizer(tapView)

	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

	}

	func addNumbersToArray(numbers: Int...) {
		self.array?.append(contentsOf: numbers)
	}


	@objc func handleTap(recognizer: UIGestureRecognizer) {
		animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2, delay: 0, options: [], animations: {
			self.madeView.transform = .init(scaleX: 3, y: 3)
		}, completion: { (_) in
			UIView.animate(withDuration: 2, animations: {
				self.madeView.transform = .identity
			})
		})

	}

	@objc func handleTapOnView(recognizer: UIGestureRecognizer) {
		animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2, delay: 0, options: [], animations: {
			self.madeView.alpha = 1.0
		}, completion: { (_) in
			UIView.animate(withDuration: 2, animations: {
				self.madeView.alpha = 0.0
			})
		})
	}

}


PlaygroundPage.current.liveView = ViewController(with: [1])
