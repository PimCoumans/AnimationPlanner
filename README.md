# AnimationPlanner

Chain multiple `UIView` animations without endlessly nesting in completion closures. Used in some of the more superfluous animations in the [OK Video](https://okvideo.app/download) app.
Very useful with @warpling‘s [`CAMediaTimingFunction` extensions](https://gist.github.com/warpling/21bef9059e47f5aad2f2955d48fd7c0c), giving you all the animation curves you need.

## How do I do this?
Add `AnimationPlanner` to your project (through 📦 SPM preferably) and use the `UIView.animateSteps()` method to start adding steps to the provided sequence, like shown below.

```swift
UIView.animateSteps { sequence in
    sequence
        .delay(0.35)
        .add(duration: 0.5, timingFunction: .quartOut) {
            view.alpha = 1
            view.center.y = self.view.bounds.midY
        }
        .delay(0.2)
        .add(duration: 0.32, timingFunction: .quintOut) {
            view.transform = CGAffineTransform(scaleX: 2, y: 2)
            view.layer.cornerRadius = 40
            view.backgroundColor = .systemRed
        }
        .delay(0.2)
        .add(duration: 0.12, timingFunction: .backOut) {
            view.backgroundColor = .systemBlue
            view.layer.cornerRadius = 0
            view.transform = .identity
        }
        .delay(0.58)
        .add(duration: 0.2, timingFunction: .circIn) {
            view.alpha = 0
            view.transform = .identity
            view.frame.origin.y = self.view.bounds.maxY
        }
} completion: { finished in
    view.removeFromSuperview()
}
```

The above code creates the following animation. For more examples see the included sample app.
<p align="center">
    <img src="Assets/sample-app.gif" width="293" height="634" />
</p>

## Installation

### Adding AnimationPlanner as a package dependency

1. Go to `File` -> `Add Packages` and select your project
3. Paste `https://github.com/PimCoumans/AnimationPlanner` in the search bar and click on "Add Package"
4. Select the target(s) in which you want to use AnimationPlanner

### Swift Package Manager

Manually AnimationPlanner as a package dependency in `package.swift`, like shown in the example below:
```swift
// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "YourProject",
  platforms: [
       .iOS(.v12),
  ],
  dependencies: [
    .package(name: "AnimationPlanner", url: "https://github.com/PimCoumans/AnimationPlanner.git", .branch("main"))
  ],
  targets: [
    .target(name: "YourProject", dependencies: ["AnimationPlanner"])
  ]
)
```

## Future stuff
While this API removes a lot of unwanted nesting in completion closures with traditional `UIView.animate...` calls, it could be tidied even more by using Swift‘s function builders, like we see used in SwiftUI. For a future release I‘m planning to refactor the code make use of that, hopefully making it look and work a little better.

Got any feedback? Please let me know! ✌🏻

https://twitter.com/pimcoumans
