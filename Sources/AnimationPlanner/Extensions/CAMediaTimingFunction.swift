import QuartzCore
// from @warpling’s https://gist.github.com/warpling/21bef9059e47f5aad2f2955d48fd7c0c
public extension CAMediaTimingFunction {

    static let linear     = CAMediaTimingFunction(name: .linear)
    static let easeOut    = CAMediaTimingFunction(name: .easeOut)
    static let easeIn     = CAMediaTimingFunction(name: .easeIn)
    static let easeInOut  = CAMediaTimingFunction(name: .easeInEaseOut)
    static let `default`  = CAMediaTimingFunction(name: .default)

    static let sineIn     = CAMediaTimingFunction(controlPoints: 0.45, 0, 1, 1)
    static let sineOut    = CAMediaTimingFunction(controlPoints: 0, 0, 0.55, 1)
    static let sineInOut  = CAMediaTimingFunction(controlPoints: 0.45, 0, 0.55, 1)

    static let quadIn     = CAMediaTimingFunction(controlPoints: 0.43, 0, 0.82, 0.60)
    static let quadOut    = CAMediaTimingFunction(controlPoints: 0.18, 0.4, 0.57, 1)
    static let quadInOut  = CAMediaTimingFunction(controlPoints: 0.43, 0, 0.57, 1)

    static let cubicIn    = CAMediaTimingFunction(controlPoints: 0.67, 0, 0.84, 0.54)
    static let cubicOut   = CAMediaTimingFunction(controlPoints: 0.16, 0.46, 0.33, 1)
    static let cubicInOut = CAMediaTimingFunction(controlPoints: 0.65, 0, 0.35, 1)

    static let quartIn    = CAMediaTimingFunction(controlPoints: 0.81, 0, 0.77, 0.34)
    static let quartOut   = CAMediaTimingFunction(controlPoints: 0.23, 0.66, 0.19, 1)
    static let quartInOut = CAMediaTimingFunction(controlPoints: 0.81, 0, 0.19, 1)

    static let quintIn    = CAMediaTimingFunction(controlPoints: 0.89, 0, 0.81, 0.27)
    static let quintOut   = CAMediaTimingFunction(controlPoints: 0.19, 0.73, 0.11, 1)
    static let quintInOut = CAMediaTimingFunction(controlPoints: 0.9, 0, 0.1, 1)

    static let expoIn     = CAMediaTimingFunction(controlPoints: 1.04, 0, 0.88, 0.49)
    static let expoOut    = CAMediaTimingFunction(controlPoints: 0.12, 0.51, -0.4, 1)
    static let expoInOut  = CAMediaTimingFunction(controlPoints: 0.95, 0, 0.05, 1)

    static let circIn     = CAMediaTimingFunction(controlPoints: 0.6, 0, 1, 0.45)
    static let circOut    = CAMediaTimingFunction(controlPoints: 1, 0.55, 0.4, 1)
    static let circInOut  = CAMediaTimingFunction(controlPoints: 0.82, 0, 0.18, 1)

    static let backIn     = CAMediaTimingFunction(controlPoints: 0.77, -0.63, 1, 1)
    static let backOut    = CAMediaTimingFunction(controlPoints: 0, 0, 0.23, 1.37)
    static let backInOut  = CAMediaTimingFunction(controlPoints: 0.77, -0.63, 0.23, 1.37)

    static let swiftOut   = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
}
