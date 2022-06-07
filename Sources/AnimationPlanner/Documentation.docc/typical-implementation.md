# Typical animation sequence

How a typical animation sequence would look and more information on the sample app available in the repository.

## Overview

A sequence basic sequence animation can be constructed with very little effort, using only two methods on ``AnimationSequence`` wrapped in one call to the `UIView` extension ``StepAnimatable/animateSteps(_:completion:)-8lxza``.

### Basic sequence

A basic linear sequence could look as follow:

```swift
UIView.animateSteps { sequence in
    sequence
        .add(duration: 0.32, timingFunction: .quintOut) {
            subview.transform = CGAffineTransform(scaleX: 2, y: 2)
            subview.layer.cornerRadius = 40
            subview.backgroundColor = .systemRed
        }
        .delay(0.2)
        .add(duration: 0.12, timingFunction: .backOut) {
            subview.backgroundColor = .systemBlue
            subview.layer.cornerRadius = 0
            subview.transform = .identity
        }
        .delay(0.58)
        .add(duration: 0.2, timingFunction: .circIn) {
            subview.alpha = 0
            subview.frame.origin.y = self.view.bounds.maxY
        }
} completion: { finished in
    subview.removeFromSuperview()
}
```

In the code shown above, the extension method ``StepAnimatable/animateSteps(_:completion:)-8lxza`` is called, where the ``AnimationSequence`` object is provided to add each step. Using the methods ``AnimationSequence/add(duration:options:timingFunction:animations:)`` and ``AnimationSequence/delay(_:)`` a simple animation sequence is constructed by changing properties on a `subview` object. In the `completion` the `subview` is removed, demonstrating how to end an animation sequence

## Sample app

In the repository, a sample app is availabe that demonstrates `AnimationPlanner` usage.

Clone the repository [github.com/PimCoumans/AnimationPlanner](https://github.com/PimCoumans/AnimationPlanner) and take a look at the Sample App. In the `ViewController` of this app `AnimationPlanner` is used to perform animations. Change set `performComplexAnimation` to `true` to make it show a complex animation that introduces advanced methods of using `AnimationPlanner`, including groups, adding steps from a loop and extending `AnimationSequence` with custom animations.
