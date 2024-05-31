//
//  HYPageDiffable.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/31.
//

import Foundation

public protocol PageDiffable {
    var diffIdentifier: String { get }
    func isEqual(to object: PageDiffable?) -> Bool
    
    // 预加载, 进入working range范围
    func prepare()
    
}

public extension PageDiffable {
    
    func prepare() {}
    
}


public extension Array<PageDiffable> {
    func contains(_ value: Element) -> Bool {
        return self.contains { $0.isEqual(to: value) }
    }
}


extension String: PageDiffable {
    
    public var diffIdentifier: String {
        return self
    }
    
    public func isEqual(to object: PageDiffable?) -> Bool {
        guard let object = object as? String else { return false}
        return self.isEqual(object)
    }
    
}
