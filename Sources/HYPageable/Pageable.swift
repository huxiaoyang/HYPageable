//
//  Pageable.swift
//  PageViewController
//
//  Created by huxiaoyang on 2023/3/24.
//

import UIKit

public protocol Pageable where Self: UIViewController {
    
    var reuseIdentifier: String { get }
    
    // 预加载, 进入复用池
    func prepareForReuse()
    
}


public extension Pageable {
    
    var reuseIdentifier: String {
        return String(describing: type(of: self))
    }
    
    func prepareForReuse() {}
}

extension UIViewController {
    public weak var pageViewController: PageViewController? {
        
        guard var parent = self.parent else { return nil }
        
        while !(parent.isKind(of: PageViewController.self)) {
            guard let pp = parent.parent else { return nil }
            parent = pp
        }
        
        return parent as? PageViewController
    }
}

public enum PagePosition {
    case previous   // 前一个
    case next       // 后一个
    case value(PageDiffable) // 特定
}
