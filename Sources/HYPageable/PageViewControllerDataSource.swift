//
//  PageViewControllerDataSource.swift
//  PageViewController
//
//  Created by huxiaoyang on 2023/3/24.
//

import UIKit

public protocol PageViewControllerDataSource: AnyObject {
        
    func objects(for pageViewController: PageViewController) -> [PageDiffable]
    
    func pageViewController(_ pageViewController: PageViewController,
                            controllerFor object: PageDiffable) -> Pageable?
    
}

