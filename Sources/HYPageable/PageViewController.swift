//
//  HYPageViewController.swift
//  HYPageViewController
//
//  Created by huxiaoyang on 2023/3/22.
//

import UIKit

public class PageViewController: UIViewController {
    
    // MARK: - public
    
    var appearanceStateHandler: ((AppearanceState) -> Void)?
    
    public var transitioning: Bool {
        return _transitioning
    }
    
    public var visibleObject: PageDiffable? {
        return _visibleNode?.value
    }
    
    public weak var dataSource: PageViewControllerDataSource? {
        get {
            return _dataSource
        }
        set {
            guard let value = newValue else {return}
            _dataSource = value
            setNeedsReload()
        }
    }
    
    public weak var delegate: PageViewControllerDelegate?
    
    // MARK: - private
    
    private var _pageLoaded: Bool = false
    private var _firstObject: PageDiffable?
    
    private var _needsReload: Bool = false
    private var _transitioning: Bool = false
    
    private typealias ObjectList = LinkedList<PageDiffable>
    private var _objectList: ObjectList? // conversion from dataSource func objects()
    
    private typealias ObjectNode = ObjectList.Node
    private var _visibleNode: ObjectNode? // current node on screen
    
    private var _visibleController: Pageable?
    private weak var _dataSource: PageViewControllerDataSource?
    
    // For instance, if working range of 2, the previous and succeeding 2 objects will be notified that they are within the working range
    private let workingRangeSize: Int
    
    // reusable controllers
    private lazy var _reusableControllers: Set<UIViewController> = {
        return Set<UIViewController>()
    }()
    
    private lazy var _reusableObjectIds: Set<String> = {
        return Set<String>()
    }()

    private lazy var _contentView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.white
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    // MARK: - life cycle
    
    public init(dataSource: PageViewControllerDataSource? = nil,
                delegate: PageViewControllerDelegate? = nil,
                workingRangeSize: Int = 0) {
        self._dataSource = dataSource
        self.delegate = delegate
        self.workingRangeSize = workingRangeSize
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(_contentView)
        setNeedsReload()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceState = .willAppear
        appearanceStateHandler?(.willAppear)
        if let child = _visibleController {
            child.setAppearanceState(.willAppear, animated: animated)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appearanceState = .didAppear
        appearanceStateHandler?(.didAppear)
        if let child = _visibleController {
            child.setAppearanceState(.didAppear, animated: animated)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceState = .willDisappear
        appearanceStateHandler?(.willDisappear)
        if let child = _visibleController {
            child.setAppearanceState(.willDisappear, animated: animated)
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        appearanceState = .didDisappear
        appearanceStateHandler?(.didDisappear)
        if let child = _visibleController {
            child.setAppearanceState(.didDisappear, animated: animated)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        _contentView.frame = view.bounds
        reloadDataIfNeeded()
        layoutVisibleViewIfNeeded()
        super.viewDidLayoutSubviews()
    }
    
    public override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }
    
    public override var childForStatusBarStyle: UIViewController? {
        return _visibleController
    }
    
    public override var childForStatusBarHidden: UIViewController? {
        return _visibleController
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        guard let child = _visibleController else {
            return .none
        }
        return child.preferredStatusBarUpdateAnimation
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let child = _visibleController else {
            return .all
        }
        return child.supportedInterfaceOrientations
    }
    
}

// MARK: - public
public extension PageViewController {
    
    func reloadData() {
        _reusableControllers.forEach { page in
            page.view.removeFromSuperview()
        }
        _reusableControllers.removeAll()
        
        _reusableObjectIds.removeAll()
        
        // trigger the object cache to be repopulate
        updateObjects()
        
        // trigger reload if needed
        reloadVisibleControllerIfNeeded()
        
        // 预处理复用池
        preload()
        
        _needsReload = false
        _pageLoaded = true
    }
    
    func display(_ position: PagePosition) {
        switch position {
        case .previous:
            guard let _ = visibleObject else { return }
            displayPrevious()
            preloadPrevious()
        case .next:
            guard let _ = visibleObject else { return }
            displayNext()
            preloadNext()
        case .value(let obj):
            guard _pageLoaded else {
                _firstObject = obj
                return
            }
            display(for: obj)
            preload()
        }
    }
    
    func currentController() -> Pageable? {
        return _visibleController
    }
    
    func dequeueReusableController(with identifier: String) -> Pageable? {
        for controller in _reusableControllers {
            guard let page = controller as? Pageable else { break }
            if page.reuseIdentifier == identifier {
                _reusableControllers.remove(controller)
                page.prepareForReuse()
                return page
            }
        }
        return nil
    }
    
}

// MARK: - switch object to display controller
private extension PageViewController {
    
    func displayNext() {
        guard let node = _visibleNode,
              let next = node.next else {
            return
        }
        
        displayController(for: next)
    }
    
    func displayPrevious() {
        guard let node = _visibleNode,
              let previous = node.previous else {
            return
        }
        
        displayController(for: previous)
    }
    
    func display(for object: PageDiffable) {
        guard let list = _objectList,
              let node = list.node(for: object) else {
            return
        }
        
        displayController(for: node)
    }
    
}

// MARK: - reload & transition
private extension PageViewController {
    
    func setNeedsReload() {
        _needsReload = true
    }
    
    func reloadDataIfNeeded() {
        if _needsReload {
            reloadData()
        }
    }
    
    func layoutVisibleViewIfNeeded() {
        guard let child = _visibleController else { return }
        child.view.frame = _contentView.bounds
    }
    
    func updateObjects() {
        if let list = _objectList {
            list.removeAll()
        }
        guard let dataSource = _dataSource else { return }
        let objs = dataSource.objects(for: self)
        _objectList = LinkedList(array: objs)
    }
    
    func reloadVisibleControllerIfNeeded() {
        guard let list = _objectList, list.count > 0 else {
            if let child = _visibleController {
                // destory controller
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
            return
        }
        
        if _visibleNode != nil {
            //  visibleObject already exists, no need to reload
            return
        }
        
        if let obj = _firstObject {

            reloadController(for: obj)
            _firstObject = nil

        } else if let obj = list.head?.value {

            reloadController(for: obj)

        }
        
    }
    
    func reloadController(for object: PageDiffable) {        
        guard let child = getController(for: object),
              child.parent == nil else {
            return
        }
        
        guard let list = _objectList,
              let node = list.node(for: object),
              shouldDisplay(controller: child, for: node) else {
            return
        }
        
        // add child controller
        addChild(child)
        child.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        _contentView.addSubview(child.view)
        child.didMove(toParent: self)
        
        // sync child life cycle
        if containerVisible() {
            syncAppearanceState(to: child)
        }
                
        // finish reload
        endDisplay(to: child, for: node)
    }
    
    private func getController(for node: ObjectNode) -> Pageable? {
        return getController(for: node.value)
    }
    
    // object to controller
    func getController(for object: PageDiffable) -> Pageable? {
        if let current = visibleObject, current.isEqual(to: object) {
            return _visibleController
        }
        guard let dataSource = _dataSource else { return nil }
        let controller = dataSource.pageViewController(self, controllerFor: object)
        return controller
    }
    
    private func displayController(for node: ObjectNode) {
        guard let fromVC = _visibleController,
              let toVC = getController(for: node),
              fromVC !== toVC,
              fromVC.reuseIdentifier != toVC.reuseIdentifier,
              shouldDisplay(controller: toVC, for: node) else {
            return
        }
        
        _transitioning = true
        // get transition animation
        let animator = animator(from: fromVC, to: toVC)
        if let animate = animator {
            // with animated transition
            willDisplay(from: fromVC, to: toVC, animated: true)
            transitioning(from: fromVC, to: toVC, for: node, animator: animate)
        } else {
            // without animation transition
            willDisplay(from: fromVC, to: toVC, animated: false)
            didDisplay(from: fromVC, to: toVC, animated: false)
            endDisplay(to: toVC, for: node)
        }
    }
    
    private func shouldDisplay(controller: Pageable, for node: ObjectNode) -> Bool {
        guard let delegate = delegate else { return true }
        return delegate.pageViewController(self, shouldDisplay: controller, forObject: node.value)
    }
    
    func willDisplay(from fromVC: Pageable, to toVC: Pageable, animated: Bool) {
        addChild(toVC)
        toVC.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        fromVC.setAppearanceState(.willDisappear, animated: animated)
        fromVC.willMove(toParent: nil)
        if containerVisible() {
            toVC.forceWillAppear(animated: animated)
        }
    }
    
    func didDisplay(from fromVC: Pageable, to toVC: Pageable, animated: Bool) {
        _contentView.addSubview(toVC.view)
        fromVC.forceDidDisappear(animated: animated)
        toVC.didMove(toParent: self)
        fromVC.view.removeFromSuperview()
        fromVC.removeFromParent()
        if containerVisible() {
            syncAppearanceState(to: toVC)
        }
    }
    
    private func endDisplay(to toVC: Pageable, for node: ObjectNode) {
        guard let delegate = delegate else { return }
        if let current = _visibleController {
            _reusableControllers.insert(current)
        }
        _visibleNode = node
        _visibleController = toVC
        delegate.pageViewController(self, didEndDisplaying: toVC, forObject: node.value)
        view.setNeedsLayout()
        setNeedsStatusBarAppearanceUpdate()
        _transitioning = false
    }
    
    private func transitioning(from fromVC: Pageable, to toVC: Pageable, for toNode: ObjectNode, animator: UIViewControllerAnimatedTransitioning) {
        guard let delegate = delegate else { return }
                
        let interactor = delegate.pageViewController(self, interactionControllerFor: animator) as? PercentDrivenInteractiveTransition
        
        // get context transitievoning
        let context = PageTransitionContext(animator: animator,
                                          interactor: interactor,
                                          from: fromVC,
                                          to: toVC)
        
        context.completionHandler = { [unowned self] completed in
            if completed {
                self.didDisplay(from: fromVC, to: toVC, animated: true)
                self.endDisplay(to: toVC, for: toNode)
            } else {
                toVC.forceDidDisappear(animated: false)
                toVC.view.removeFromSuperview()
                self.syncAppearanceState(to: fromVC)
                self._transitioning = false
            }
            
            animator.animationEnded?(completed) // optional
        }
        
        if let inter = interactor, inter.wantsInteractiveStart {
            animator.animateTransition(using: context)
            inter.startInteractiveTransition(context)
        } else {
            _contentView.layer.speed = 1.0
            animator.animateTransition(using: context)
//            endDisplay(to: toVC, for: toNode)
        }
    }
    
    func animator(from fromVC: Pageable, to toVC: Pageable) -> UIViewControllerAnimatedTransitioning? {
        guard let delegate = delegate else { return nil }
        return delegate.pageViewController(self, animationControllerForFrom: fromVC, to: toVC)
    }
    
    func interaction(for animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let delegate = delegate else { return nil }
        return delegate.pageViewController(self, interactionControllerFor: animator)
    }
    
}

// MARK: - working range
private extension PageViewController {
    
    func preloadNext() {
        guard var node = _visibleNode else { return }
        var index = workingRangeSize
        while index > 0, let next = node.next {
            if _reusableObjectIds.contains(next.value.diffIdentifier) {
                node = next
                continue
            }
            if let controller = getController(for: next) {
                next.value.prepare()
                _reusableObjectIds.insert(next.value.diffIdentifier)
                _reusableControllers.insert(controller)
            }
            node = next
            index -= 1
        }
    }
    
    func preloadPrevious() {
        guard var node = _visibleNode else { return }
        var index = workingRangeSize
        while index > 0, let previous = node.previous {
            if _reusableObjectIds.contains(previous.value.diffIdentifier) {
                node = previous
                continue
            }
            if let controller = getController(for: previous) {
                previous.value.prepare()
                _reusableObjectIds.insert(previous.value.diffIdentifier)
                _reusableControllers.insert(controller)
            }
            node = previous
            index -= 1
        }
    }
    
    func preload() {
        preloadNext()
        preloadPrevious()
    }
    
}

// MARK: - private appearance state
private extension PageViewController {
    
    private func containerVisible() -> Bool {
        let visible = appearanceState == .didAppear
                      || appearanceState == .willAppear
                      || appearanceState == .willDisappear
        return visible && (view.window != nil)
    }
    
    private func syncAppearanceState(to controller: UIViewController) {
        switch appearanceState {
        case .willAppear:
            controller.forceWillAppear(animated: false)
        case .willDisappear:
            controller.forceWillDisappear(animated: false)
        case .didAppear:
            controller.forceDidAppear(animated: false)
        default:
            break
        }
    }
    
}
