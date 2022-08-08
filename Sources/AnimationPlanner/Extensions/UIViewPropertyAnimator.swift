import UIKit

extension UIViewPropertyAnimator {
	convenience init(duration: TimeInterval, timingFunction: CAMediaTimingFunction, animations: @escaping () -> Void) {
		let controlPoints: [CGPoint] = (1...2).map { index in
			var points: [Float] = [0, 0]
			timingFunction.getControlPoint(at: index, values: &points)
			return CGPoint(x: CGFloat(points[0]), y: CGFloat(points[1]))
		}
		self.init(duration: duration, controlPoint1: controlPoints[0], controlPoint2: controlPoints[1], animations: animations)
	}
}
