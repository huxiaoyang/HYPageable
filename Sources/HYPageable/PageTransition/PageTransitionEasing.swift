//
//  HYTransitionEasing.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/22.
//

import UIKit

typealias TransitionEasing = (_ value: Double) -> Double

internal func curveEaseLinear() -> TransitionEasing {
    return { input in
        return input
    }
}

internal func curveEaseIn() -> TransitionEasing {
    return { input in
        return sin((input - 1) * (.pi / 2)) + 1
    }
}

internal func curveEaseOut() -> TransitionEasing {
    return { input in
        return sin(input * (.pi / 2))
    }
}

internal func curveEaseInOut() -> TransitionEasing {
    return { input in
        return 0.5 * (1 - cos(input * (.pi / 2)))
    }
}

internal class PageTransitionEasing {

    static func frames(with easing: TransitionEasing,
                         from begin: Double,
                         to end: Double,
                         count: Int) -> [Double] {
        
        var result = [Double]()
        var t: Double = 0
        var dt: Double = 1.0
        
        if count > 1 {
            dt = 1.0 / Double(count)
        }
        
        for _ in 0...count {
            var value = begin + easing(t) * (end - begin)
            if value < 0.000001 {
                value = 0.0
            }
            result.append(value)
            t += dt
        }
        
        return result
    }
    
}


