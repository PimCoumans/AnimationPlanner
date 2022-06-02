//
//  ViewController.swift
//  AnimationPlanner-Sample
//
//  Created by Pim on 02/06/2022.
//

import UIKit
import AnimationPlanner

class ViewController: UIViewController {

    lazy var thing: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(thing)
    }

    let performComplexAnimation: Bool = false

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
    
    func setInitialThingState() -> UIView {
        thing.alpha = 0
        thing.center.x = view.bounds.midX
        thing.frame.origin.y = view.bounds.minY
        thing.backgroundColor = .systemOrange
        thing.layer.cornerRadius = 16
        return thing
    }
    
    func runSimpleAnimation() {
        UIView.animateSteps { sequence in
            let view = setInitialThingState()
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
            self.runSimpleAnimation()
        }
    }
    
    func runComplexAnimation() {
        
        UIView.animateSteps { sequence in
            thing.alpha = 0
            let quarterHeight = view.bounds.height / 4
            
            sequence.delay(0.2)
                .add(duration: 1, options: .curveEaseOut) {
                    self.thing.alpha = 1
                    self.thing.frame.origin.y = quarterHeight
                }
                .delay(0.2)
                .add(duration: 0.10, options: [.curveEaseOut]) {
                    self.thing.transform = self.thing.transform.scaledBy(x: 0.9, y: 0.9)
                    self.thing.layer.cornerRadius = 40
                }
                .add(duration: 1) {
                    self.thing.frame.origin.y += quarterHeight
                }
                .add(duration: 0.15, options: .curveEaseInOut) {
                    self.thing.transform = self.thing.transform.scaledBy(x: 1.4, y: 1.4)
                    self.thing.backgroundColor = .systemBlue
                }
                .add(duration: 0.1, options: .curveEaseInOut) {
                    self.thing.transform = .identity
                    self.thing.backgroundColor = .systemBlue
                }
                .add(duration: 1) {
                    self.thing.frame.origin.y += quarterHeight
                }
                .add(duration: 0.1, options: .curveEaseInOut) {
                    self.thing.transform = CGAffineTransform(rotationAngle: .pi / 4)
                    self.thing.backgroundColor = .systemOrange
                }
                .delay(1)
                .add(duration: 0.2, options: .curveEaseIn) {
                    self.thing.alpha = 0
                    self.thing.transform = CGAffineTransform(translationX: 0, y: quarterHeight)
                }
        } completion: { finished in
            print("DONE")
        }
        
    }
}

