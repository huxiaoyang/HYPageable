//
//  HYTransitionContext.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/22.
//

import UIKit

internal class PageTransitionContext: NSObject {
    
    typealias onCompletionHandler = (Bool) -> Void
    internal var completionHandler: onCompletionHandler?
    
    fileprivate var animator: UIViewControllerAnimatedTransitioning?
    fileprivate var interactor: UIViewControllerInteractiveTransitioning?
    fileprivate var container: UIView?
    
    fileprivate var controllers: [UITransitionContextViewControllerKey: UIViewController] = [:]
    fileprivate var views: [UITransitionContextViewKey: UIView] = [:]
    
    fileprivate var animating: Bool = false
    fileprivate var interacting: Bool = false
    fileprivate var cancelled: Bool = false
    
    /// 处理闪屏问题占位图
    fileprivate var splashPlaceholder: UIView?
    
    fileprivate var previousMediaTime: CFTimeInterval = CACurrentMediaTime()
    fileprivate var percentComplete: CGFloat = 0
    
    /// cancel 后的动画帧
    fileprivate var frameIndex: Int = 0
    fileprivate lazy var frames: [Double] = {
        var duration = transitionDuration
        if let speed = interactor?.completionSpeed, speed > 0 {
            duration = (1 - percentComplete) * transitionDuration / speed
        }
        let easing = completionEasing()
        let fromValue: Double = container?.layer.timeOffset ?? 0
        let toValue: Double = cancelled ? 0 : transitionDuration
        var count = Int(duration * 60) // 帧数
        if #available(iOS 15.0, *) {
            count = Int(duration * 120) // 帧数
        }
        let values = PageTransitionEasing.frames(with: easing, from: fromValue, to: toValue, count: count)
        return values
    }()
    
    
    internal init(animator anima: UIViewControllerAnimatedTransitioning?,
                interactor inter: UIViewControllerInteractiveTransitioning?,
                from fromVC: UIViewController,
                to toVC: UIViewController) {
        super.init()
        
        animator = anima
        interactor = inter
        
        container = fromVC.view.superview
        container?.layer.speed = .zero
        
        controllers = [UITransitionContextViewControllerKey.from: fromVC,
                       UITransitionContextViewControllerKey.to: toVC]
        views = [UITransitionContextViewKey.from: fromVC.view,
                 UITransitionContextViewKey.to: toVC.view]
    }
    
    private func completionEasing() -> TransitionEasing {
        guard let interactor = interactor, let curve = interactor.completionCurve else {
            return curveEaseLinear()
        }
        switch curve {
        case .linear:
            return curveEaseLinear()
        case.easeIn:
            return curveEaseIn()
        case .easeOut:
            return curveEaseOut()
        case .easeInOut:
            return curveEaseInOut()
        @unknown default:
            return curveEaseLinear()
        }
    }
    
}

extension PageTransitionContext: UIViewControllerContextTransitioning {
    var targetTransform: CGAffineTransform {
        get {
            return .identity
        }
    }
    
    var containerView: UIView {
        get {
            guard let view = container else { return UIView() }
            return view
        }
    }

    var isAnimated: Bool {
        get {
            return self.animating
        }
    }

    var isInteractive: Bool {
        get {
            return self.interacting
        }
    }

    var transitionWasCancelled: Bool {
        get {
            return self.cancelled
        }
    }

    var presentationStyle: UIModalPresentationStyle {
        get {
            return .overCurrentContext
        }
    }
    
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        self.interacting = true
        let diff = CACurrentMediaTime() - previousMediaTime
        var frameRate = 60
        if #available(iOS 15.0, *) {
            frameRate = 120
        }
        if diff > (1.0 / Double(frameRate)) {
            self.percentComplete = percentComplete
            self.previousMediaTime = CACurrentMediaTime()
            if let view = container {
                view.layer.timeOffset = percentComplete * transitionDuration
            }
        }
    }

    func finishInteractiveTransition() {
        self.cancelled = false
        autoCompletionAnimation()
    }

    func cancelInteractiveTransition() {
        cancelled = true
        autoCompletionAnimation()
    }

    func pauseInteractiveTransition() {
        guard let layer = container?.layer else { return }
        let pauseTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = .zero
        layer.timeOffset = pauseTime
    }

    func completeTransition(_ didComplete: Bool) {
        if let view = splashPlaceholder {
            view.removeFromSuperview()
            splashPlaceholder = nil
        }
        if let completion = completionHandler {
            completion(didComplete)
        }
        if let view = container {
            view.layer.beginTime = 0
        }
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return controllers[key]
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return views[key]
    }

    func initialFrame(for vc: UIViewController) -> CGRect {
        return .zero
    }

    func finalFrame(for vc: UIViewController) -> CGRect {
        return self.containerView.bounds
    }
    
    var transitionDuration: CGFloat {
        get {
            guard let animator = self.animator else { return 0 }
            return animator.transitionDuration(using: self)
        }
    }
    
    private func autoCompletionAnimation() {
        self.interacting = true
        self.frameIndex = 0
        let link = CADisplayLink(target: self, selector: #selector(tickCompletionAnimation(_:)))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 120, maximum: 120)
        }
        link.add(to: RunLoop.main, forMode: .common)
    }
    
    @objc private func tickCompletionAnimation(_ sender: CADisplayLink) {
        guard let view = self.container, view.layer.timeOffset > 0 else {
            transitionCompleted(displayLink: sender)
            return
        }
        var timeOffset: Double = 0.0
        if frameIndex < frames.count {
            timeOffset = frames[frameIndex]
        }
        percentComplete = timeOffset / transitionDuration
        view.layer.timeOffset = timeOffset
        if timeOffset > 0, timeOffset < transitionDuration {
            frameIndex += 1
        } else {
            transitionCompleted(displayLink: sender)
        }
    }
    
    private func transitionCompleted(displayLink: CADisplayLink) {
        displayLink.invalidate()
        guard let layer = container?.layer else { return }
        if cancelled {
            layer.speed = 1.0
            layer.timeOffset = 0.0
            resolveSplashScreen() // 处理闪屏问题
        } else {
            let pausedTime = layer.timeOffset
            layer.speed = 1.0
            layer.timeOffset = 0.0
            layer.beginTime = 0.0
            let timeSincePause = (layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime) / Double(layer.speed)
            layer.beginTime = timeSincePause
        }
    }
    
    private func resolveSplashScreen() {
        guard let fromView = views[UITransitionContextViewKey.from],
              let snap = fromView.snapshotView(afterScreenUpdates: false),
              let view = container else {
            return
        }
        snap.frame = view.bounds
        view.addSubview(snap)
        splashPlaceholder = snap
    }
    
}
