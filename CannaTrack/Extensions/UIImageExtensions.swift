import UIKit

extension UIImage {
    
    /// initialize an image with a NSURL
    convenience init(url: NSURL) {
		self.init(data: NSData(contentsOf: url as URL)! as Data)!
    }
    
}
