[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPimCoumans%2FAnimationPlanner%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/PimCoumans/AnimationPlanner)
 [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPimCoumans%2FAnimationPlanner%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/PimCoumans/AnimationPlanner)

![Animation Planner logo](Assets/AnimationPlanner.png)
 
# AnimationPlanner

⛓ Chain multiple `UIView` animations without endless closure nesting. Create your animation sequence all on the same indentation level using a clear, concise syntax. 

🤹 Used for all exuberant animations in [OK Video 📲](https://okvideo.app/download) 

📖 Check out the [documentation](https://swiftpackageindex.com/PimCoumans/AnimationPlanner/main/documentation/animationplanner) to get up to speed, or read on to see a little example.


## How do I plan my animations?

📦 Add `AnimationPlanner` to your project (using Swift Package manager) and start typing `AnimationPlanner.plan` to embark on your animation journey. Like what‘s happening in the code below.

```swift
AnimationPlanner.plan {
    Animate(duration: 0.32, timingFunction: .quintOut) {
        view.alpha = 1
        view.center.y = self.view.bounds.midY
    }
    Wait(0.2)
    Animate(duration: 0.32) {
        view.transform = CGAffineTransform(scaleX: 2, y: 2)
        view.layer.cornerRadius = 40
        view.backgroundColor = .systemRed
    }.timingFunction(.quintOut)
    Wait(0.2)
    AnimateSpring(duration: 0.25, dampingRatio: 0.52) {
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 0
        view.transform = .identity
    }
    Wait(0.58)
    Animate(duration: 0.2) {
        view.alpha = 0
        view.transform = .identity
        view.frame.origin.y = self.view.bounds.maxY
    }.timingFunction(.circIn)
}.onComplete { finished in
    view.removeFromSuperview()
}
```

The above code results in the following animation sequence. For more examples see the [Sample App](Sample%20App/AnimationPlanner-Sample/ViewController.swift) available when cloning the repo.
<p align="center">
    <img src="Assets/sample-app.gif" width="293" height="443" />
</p>

_**Note:** The example uses [custom extension methods](Sources/AnimationPlanner/Extensions/CAMediaTimingFunction.swift) on `CAMediaTimingFunction`, included with the framework_

## Installation

### 🛠 Adding AnimationPlanner as a package dependency

1. Go to `File` -> `Add Packages`
3. Paste `https://github.com/PimCoumans/AnimationPlanner` in the search bar and click on "Add Package"
4. Select the target(s) in which you want to use AnimationPlanner

### 📦 Swift Package Manager

Manually add AnimationPlanner as a package dependency in `package.swift`, by updating your package definition with: 

```swift
  dependencies: [
    .package(name: "AnimationPlanner", url: "https://github.com/PimCoumans/AnimationPlanner.git", .branch("main"))
  ],
```

And updating your target‘s dependencies property with `dependencies: ["AnimationPlanner"]`

## 🔮 Future plans
 
While this API removes a lot of unwanted nesting in completion closures when using traditional `UIView.animate...` calls, a project is never finished and for future versions I have the following plans:
 - Remove usage of inaccurate `DispatchQueue.main.asyncAfter`, currently used to add delays for non-`UIView` animations or bridging gaps between steps.
 - Maybe even allow this package to play more nicely with SwiftUI? No idea what that would look like though, any ideas?
 
Got any feedback or suggestions? Please let me know! ✌🏻

→ [twitter.com/pimcoumans](https://twitter.com/pimcoumans)
