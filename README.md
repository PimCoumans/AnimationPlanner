# AnimationPlanner

Chain multiple `UIView` animations without endlessly nesting in completion closures.

```swift
UIView.animateSteps { sequence in
    sequence
        .delay(0.5)
        .add (duration: 0.2, options: .curveEaseInOut) {
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        .delay(1)
        .add(duration: 0.5, options: .curveEaseIn) {
            view.transform = .identity
        }
        .delay(1)
        .add(duration: 0.25) {
            view.alpha = 0
        }
} completion: { _ in
    view.isHidden = true
    view.alpha = 1
}
```
