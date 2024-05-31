//
//  HYPercentDrivenInteractiveTransition.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/22.
//

import UIKit

open class PercentDrivenInteractiveTransition: NSObject {
    
    private var _transitionContext: PageTransitionContext?
//    private var animator: UIViewControllerAnimatedTransitioning? {
//        get {
//            guard let context = _transitionContext else { return nil}
//            return context.ani
//        }
//    }
    
    public var percentComplete: CGFloat!
    
    private var _completionSpeed: Double = 1.0
    private var _completionCurve: UIView.AnimationCurve = .linear
    private var _wantsInteractiveStart: Bool = true
    
    public var duration: CGFloat {
        get {
            guard let context = _transitionContext else { return 0 }
            return context.transitionDuration
        }
    }
    
    public func update(_ percentComplete: CGFloat) {
        self.percentComplete = percentComplete
        _transitionContext?.updateInteractiveTransition(percentComplete)
    }
    
    public func finish() {
        _transitionContext?.finishInteractiveTransition()
    }

    public func cancel() {
        _transitionContext?.cancelInteractiveTransition()
    }
    
    @available(iOS 10.0, *)
    public  func pause() {
        _transitionContext?.pauseInteractiveTransition()
    }
    
}


extension PercentDrivenInteractiveTransition: UIViewControllerInteractiveTransitioning {
    
    public var wantsInteractiveStart: Bool {
        get { return _wantsInteractiveStart}
        set { _wantsInteractiveStart = newValue }
    }
    
    public var completionSpeed: CGFloat {
        get { return _completionSpeed }
        set { _completionSpeed = newValue }
    }
    
    public var completionCurve: UIView.AnimationCurve {
        get { return _completionCurve }
        set { _completionCurve = newValue }
    }
    
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let context = transitionContext as? PageTransitionContext else { return }
        _transitionContext = context
    }
    
}
