//
//  HYPageViewControllerDelegate.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/24.
//

import UIKit

public protocol PageViewControllerDelegate: AnyObject {
    
    func pageViewController(_ pageViewController: PageViewController,
                            shouldDisplay controller: Pageable,
                            forObject object: PageDiffable) -> Bool

    func pageViewController(_ pageViewController: PageViewController,
                            didEndDisplaying controller: Pageable,
                            forObject object: PageDiffable)
    
    func pageViewController(_ pageViewController: PageViewController,
                            animationControllerForFrom fromVC: Pageable,
                            to toVC: Pageable) -> UIViewControllerAnimatedTransitioning?
    
    func pageViewController(_ pageViewController: PageViewController,
                            interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    
}

public extension PageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: PageViewController,
                            shouldDisplay controller: Pageable,
                            forObject object: PageDiffable) -> Bool {
        return true
    }

    func pageViewController(_ pageViewController: PageViewController,
                            didEndDisplaying controller: Pageable,
                            forObject object: PageDiffable) {
        
    }
    
    func pageViewController(_ pageViewController: PageViewController,
                            animationControllerForFrom fromVC: Pageable,
                            to toVC: Pageable) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
    
    func pageViewController(_ pageViewController: PageViewController,
                            interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
}
