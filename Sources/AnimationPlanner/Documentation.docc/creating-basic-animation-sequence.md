# Creating a basic animation sequence

An example of how a typical animation sequence would look, how it‘s created and more information on the sample app available in the repository.

## Overview

A basic sequence animation can be constructed with very little effort, using only two structs provided through the animation builder in ``AnimationPlanner/AnimationPlanner/plan(animations:completion:)``. Two modifiers are used to provide the animation with more customization.

### Basic sequence

A basic linear sequence could look as follow:

```swift
AnimationPlanner.plan {
    Animate(duration: 0.5) {
        subview.transform = CGAffineTransform(scaleX: 2, y: 2)
        subview.layer.cornerRadius = 40
        subview.backgroundColor = .systemRed
    }.timingFunction(.quintOut)
    Wait(0.2)
    Animate(duration: 0.45) {
        subview.backgroundColor = .systemBlue
        subview.layer.cornerRadius = 0
        subview.transform = .identity
    }.spring(damping: 0.68)
    Wait(0.2)
    Animate(duration: 0.2) {
        subview.alpha = 0
        subview.frame.origin.y = self.view.bounds.maxY
    }
} completion: { finished in
    subview.removeFromSuperview()
}
```

In the code shown above, an animation sequence is started with ``AnimationPlanner/AnimationPlanner/plan(animations:completion:)`` where each animation is added. Using the structs ``Animate`` and ``Wait`` a simple animation sequence is constructed by changing properties on a `subview` object. In the `completion` handler the `subview` is removed, demonstrating how to end an animation sequence.

The first to ``Animate`` structs have modifiers applied. ``AnimationModifiers/timingFunction(_:)`` changes the interpolation method of the animation by providing a `CAMediaTimingFunction`. AnimationPlanner already provides a lot of custom available timing functions like `.quintOut` used here.

The second modifier changes the animation to a spring-based animation with ``SpringModifier/spring(damping:initialVelocity:)-33bwh`` and sets its daming ratio to the magic number of `0.68`. Spring-based animations in AnimationPlanner result in a `UIView` animation with `usingSpringWithDamping` where you can set a `dampingRatio` and `initialVelocity`.

## Sample app

In the repository, a sample app is availabe that demonstrates `AnimationPlanner` usage.

Clone the repository [github.com/PimCoumans/AnimationPlanner](https://github.com/PimCoumans/AnimationPlanner) and take a look at the Sample App. In the `ViewController` of this app `AnimationPlanner` is used to perform animations. Change set `performComplexAnimation` to `true` to make it show a complex animation that introduces advanced methods of using `AnimationPlanner`, including groups, adding steps from a loop and extending `AnimationSequence` with custom animations.
