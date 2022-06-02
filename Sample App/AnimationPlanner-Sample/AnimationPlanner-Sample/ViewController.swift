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
                }
                .add(duration: 0.1, options: .curveEaseInOut) {
                    view.transform = .identity
                    view.backgroundColor = .systemBlue
                }
                .delay(1)
            
            // Adding multiple steps from a loop is pretty
            // straightforward
            (0..<4).map({ CGFloat($0) / 4 }).forEach { offset in
                sequence.add(duration: 0.2, timingFunction: .backOut) {
                    view.transform = CGAffineTransform(
                        rotationAngle: .pi * offset
                    ).scaledBy(
                        x: 1 + offset,
                        y: 1 + offset)
                    view.alpha = 1 - (offset / 2)
                }
                .delay(0.25)
            }
            
            // Continue the chain again by calling the next step on the sequence object
            sequence
                .delay(0.35)
                .add(duration: 1, timingFunction: .quadInOut) {
                    view.transform = .identity
                    view.frame.origin.y += quarterHeight
                    view.alpha = 1
                    view.backgroundColor = .systemPink
                }
                .delay(0.5)
                .addGroup { group in
                    // A group performs all of its animations at once,
                    // finishing when the longest animation completes
                    // Use a delay for a staggered effect
                    group.animate(duration: 0.5, delay: 0.2, timingFunction: .backOut) {
                        view.transform = CGAffineTransform(translationX: 50, y: 0)
                    }
                    .animate(duration: 0.2, delay: 0.1, timingFunction: .cubicOut) {
                        view.layer.borderColor = UIColor.systemBlue.cgColor
                        view.layer.borderWidth = 4
                    }
                    .animate(duration: 1) {
                        view.backgroundColor = .systemBlue
                    }
                }
                .delay(0.32)
                .add(duration: 0.5, timingFunction: .quintIn) {
                    view.alpha = 0
                    // you can use values set in previous animations
                    // as the animations are created after the previous animation completes
                    view.transform = view.transform.translatedBy(x: 0, y: quarterHeight)
                }
        } completion: { finished in
            // Let‘s watch that again, shall we?
            self.runComplexAnimation()
        }
        
    }
}

