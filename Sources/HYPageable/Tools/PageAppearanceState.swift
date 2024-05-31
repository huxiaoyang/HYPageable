//
//  PageAppearanceState.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/22.
//

import UIKit

internal enum AppearanceState {
    case unknown
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
}

internal extension UIViewController {
    
    private static var _stateMap = [String: AppearanceState]()
    var appearanceState: AppearanceState {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIViewController._stateMap[tmpAddress] ?? .unknown
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIViewController._stateMap[tmpAddress] = newValue
        }
    }
    
    func setAppearanceState(_ state: AppearanceState, animated: Bool) {
        guard self.isViewLoaded else {
            errorLog("view hasn't been loaded yet. \(state)")
            return
        }
        
        switch state {
        case .unknown:
            break
        case .willAppear:
            setAppearanceWillAppear(animated: animated)
        case .didAppear:
            setAppearanceDidAppear(animated: animated)
        case .willDisappear:
            setAppearanceWillDisappear(animated: animated)
        case .didDisappear:
            setAppearanceDidDisappear(animated: animated)
        }
    }
    
    func forceWillAppear(animated: Bool) {
        if appearanceState == .willAppear {
            errorLog("force willAppear state chould not be changed.")
            return
        }
        if appearanceState == .didAppear {
            setAppearanceState(.willDisappear, animated: animated)
        }
        setAppearanceState(.willAppear, animated: animated)
    }
    
    func forceDidAppear(animated: Bool) {
        if appearanceState == .didAppear {
            errorLog("force didAppear state chould not be changed.")
            return
        }
        if appearanceState != .willAppear {
            setAppearanceState(.willAppear, animated: animated)
        }
        setAppearanceState(.didAppear, animated: animated)
    }
    
    func forceWillDisappear(animated: Bool) {
        if appearanceState == .willDisappear {
            errorLog("force willDisappear state chould not be changed.")
            return
        }
        if appearanceState == .unknown || appearanceState == .didDisappear {
            setAppearanceState(.willAppear, animated: animated)
        }
        setAppearanceState(.willDisappear, animated: animated)
    }
    
    func forceDidDisappear(animated: Bool) {
        if appearanceState == .didDisappear || appearanceState == .unknown {
            errorLog("force didDisappear state chould not be changed.")
            return
        }
        if appearanceState == .willAppear || appearanceState == .didAppear {
            setAppearanceState(.willDisappear, animated: animated)
        }
        setAppearanceState(.didDisappear, animated: animated)
    }
    
    private func setAppearanceWillAppear(animated: Bool) {
        if appearanceState != .willAppear && appearanceState != .didAppear {
            beginAppearanceTransition(true, animated: animated)
            appearanceState = .willAppear
        } else {
            errorLog("willAppear state chould not be changed.")
        }
    }
    
    private func setAppearanceDidAppear(animated: Bool) {
        if appearanceState == .willAppear {
            endAppearanceTransition()
            appearanceState = .didAppear
        } else {
            errorLog("didAppear state chould not be changed.")
        }
    }
    
    private func setAppearanceWillDisappear(animated: Bool) {
        if appearanceState != .unknown && appearanceState != .willDisappear && appearanceState != .didDisappear {
            beginAppearanceTransition(false, animated: animated)
            appearanceState = .willDisappear
        } else {
            errorLog("willDisappear state chould not be changed.")
        }
    }
    
    private func setAppearanceDidDisappear(animated: Bool) {
        if appearanceState == .willDisappear {
            endAppearanceTransition()
            appearanceState = .didDisappear
        } else {
            errorLog("didDisappear state chould not be changed.")
        }
    }
    
    private func errorLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator)
    }
    
}
