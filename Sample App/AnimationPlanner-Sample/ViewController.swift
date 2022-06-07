//
//  ViewController.swift
//  AnimationPlanner-Sample
//
//  Created by Pim on 02/06/2022.
//

import UIKit
import AnimationPlanner

class ViewController: UIViewController {

    lazy var subview: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(subview)
    }

    let performComplexAnimation: Bool = false // Set to true to run a more complex animation

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if performComplexAnimation {
            runComplexAnimation()
        } else {
            runSimpleAnimation()
        }
    }
}

extension ViewController {
    
    func setInitialSubviewState() -> UIView {
        subview.alpha = 0
        subview.transform = .identity
        subview.frame.size = CGSize(width: 100, height: 100)
        subview.center.x = view.bounds.midX
        subview.frame.origin.y = view.bounds.minY
        subview.backgroundColor = .systemOrange
        subview.layer.cornerRadius = 16
        subview.layer.borderWidth = 0
        subview.layer.borderColor = nil
        return subview
    }
    
    func runSimpleAnimation() {
        UIView.animateSteps { sequence in
            let view = setInitialSubviewState()
            sequence
                .delay(0.35) // A delay waits for the given amount of seconds to start the next step
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
            // Just to keep the flow going, let‘s run the animation again
            self.runSimpleAnimation()
        }
    }
    
    func runComplexAnimation() {
        
        var sneakyCopy: UIView! // Don‘t worry, you‘ll see later
        
        UIView.animateSteps { sequence in
            let quarterHeight = view.bounds.height / 4
            let view = setInitialSubviewState()
            
            sequence
                .delay(0.2)
                .add(duration: 1, timingFunction: .quartOut) {
                    view.alpha = 1
                    view.center.y = quarterHeight
                }
                .delay(0.2)
                .add(duration: 0.35, timingFunction: .backOut) {
                    view.transform = view.transform.scaledBy(x: 0.9, y: 0.9)
                    view.layer.cornerRadius = 40
                }
                .add(duration: 1, timingFunction: .cubicInOut) {
                    view.frame.origin.y += quarterHeight
                    view.transform = .identity
                }
                .delay(0.32)
            
            // Adding multiple steps from a loop is pretty straightforward
            (1...4).map({ CGFloat($0) / 4 }).forEach { offset in
                let reversed = 1 - offset
                let initialCornerRadius = view.layer.cornerRadius
                sequence.add(duration: 0.2, timingFunction: .backOut) {
                    view.transform = CGAffineTransform(
                        rotationAngle: .pi * offset
                    ).scaledBy(
                        x: 1 + offset / 2,
                        y: 1 + offset / 2)
                    view.layer.cornerRadius = initialCornerRadius * reversed
                }
                .delay(0.25)
            }
            
            // Continue the chain again by calling the next step on the sequence object
            sequence
                .add(duration: 0.01, animations: {
                    view.transform = view.transform.rotated(by: .pi) // reset rotation
                })
                .add(duration: 0.01, animations: {
                    sneakyCopy = view.sneakyCopy()
                })
                // Example of using a custom extension (defined further down) for a specific animation
                .shake(view)
                .add(duration: 0.25, timingFunction: .backOut, animations: {
                    sneakyCopy.isHidden = false
                    sneakyCopy.transform = CGAffineTransform(translationX: 0, y: -view.frame.height - 20)
                    sneakyCopy.backgroundColor = .systemYellow
                })
                .delay(0.35)
                .add(duration: 1.2, timingFunction: .quartInOut) {
                    view.transform = .identity
                    let offset = view.frame.origin.y + quarterHeight
                    view.frame.origin = CGPoint(x: view.frame.minX - (view.frame.width / 2) - 10, y: offset)
                    sneakyCopy.frame = view.frame.offsetBy(dx: view.frame.width + 20, dy: 0)
                    view.backgroundColor = .systemPink
                }
                .delay(0.5)
                .addGroup { group in
                    // A group performs all of its animations at once,
                    // finishing when the longest animation completes
                    // Use a delay for a staggered effect
                    group.animate(duration: 0.5, delay: 0.2, timingFunction: .backOut) {
                        sneakyCopy.transform = CGAffineTransform(translationX: 0, y: -50).concatenating(sneakyCopy.transform)
                    }
                    .animate(duration: 0.2, delay: 0.1, timingFunction: .cubicOut) {
                        view.layer.borderColor = view.backgroundColor?.cgColor
                        view.layer.borderWidth = 4
                        sneakyCopy.layer.borderColor = sneakyCopy.backgroundColor?.cgColor
                        sneakyCopy.layer.borderWidth = 4
                    }
                    .animate(duration: 1) {
                        let viewColor = view.backgroundColor
                        view.backgroundColor = sneakyCopy.backgroundColor
                        sneakyCopy.backgroundColor = viewColor
                    }
                }
                .delay(0.32)
                .add(duration: 0.5, timingFunction: .quintIn) {
                    view.alpha = 0
                    sneakyCopy?.alpha = 0
                    // you can use values set in previous animations
                    // as the animations are created after the previous animation completes
                    view.transform = view.transform.translatedBy(x: 0, y: quarterHeight)
                    sneakyCopy?.transform = view.transform.translatedBy(x: 0, y: quarterHeight)
                }
        } completion: { finished in
            // Let‘s watch that again, shall we?
            self.runComplexAnimation()
        }
        
    }
}

extension AnimationSequence {
    /// Adds a custom shake animation on the provided view
    /// - Parameter view: View to which the transform should be applied
    /// - Returns: Extension methods ideally should return `Self` so each method call can be chained
    func shake(_ view: UIView) -> Self {
        var baseTransform: CGAffineTransform = .identity
        add(duration: 0) {
            // Get the current transform of the view right before applying random offset
            baseTransform = view.transform
        }
        let count = 50
        let maxRadius: CGFloat = 4
        for index in 0..count {
            let radius = CGFloat(index) / CGFloat(count) * maxRadius
            add(duration: 0.015, timingFunction: .quintInOut) {
                view.transform = baseTransform
                    .translatedBy(
                        x:CGFloat.random(in: -radius...radius),
                        y: CGFloat.random(in: -radius...radius)
                    )
            }
        }
        return self
    }
}

extension UIView {
    func sneakyCopy() -> Self? {
        do {
            let archiver = NSKeyedArchiver(requiringSecureCoding: false)
            archiver.encodeRootObject(self)
            let data = archiver.encodedData
            
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false

            guard let view = unarchiver.decodeObject() as? Self else {
                return nil
            }
            view.isHidden = true
            superview?.insertSubview(view, belowSubview: self)
            return view
        }
        catch {
            print(error)
            return nil
        }
    }
}

