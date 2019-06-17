//
//  KeyboardDodger.swift
//  KeyboardDodger
//
//  Created by Daniel Clelland on 5/12/17.
//  Copyright (c) 2017 Trade Me. All rights reserved.
//

import UIKit

// MARK: Keyboard dodger behavior

/// The way the keyboard constraint handler updates its constraint.
@objc public enum KeyboardDodgerBehavior: Int {
    
    /// The keyboard constraint handler updates its constraint while the keyboard's frame is changing.
    case updateWithKeyboardChange
    
    /// The keyboard constraint handler updates its constraint after the keyboard's frame has changed.
    /// This behaviour may be desired when we don't know what the constraint is going to be until after the keyboard has moved.
    ///
    /// I should describe the actual scenario that prompted this:
    ///
    /// Let's say you have a form sheet view controller on an iPad in landscape mode, and you want to move its contents out of the way when you show the keyboard. When you present
    /// the keyboard, UIKit also moves the presented view controller upwards in order to maximise the space available. This is helpful, but as the view is no longer in the same place,
    /// the constraint handler's calculations are rendered incorrect. In this case it might be better to wait until after the transition before updating your constraints.
    case updateAfterKeyboardChange
}

// MARK: - Keyboard dodger delegate

/// Optional messages that can be received as the keyboard is shown/hidden.
@objc public protocol KeyboardDodgerDelegate: class {
    
    /// Called when the constraint handler is about to update its constraint.
    @objc optional func keyboardDodger(_ keyboardDodger: KeyboardDodger, willUpdateConstraintWith transition: KeyboardDodgerTransition)
    
    /// Called when the constraint handler has finished updating its constraint.
    @objc optional func keyboardDodger(_ keyboardDodger: KeyboardDodger, didUpdateConstraintWith transition: KeyboardDodgerTransition)
    
    /// Called when the keyboard is about to reset its constraint to its original value.
    @objc optional func keyboardDodger(_ keyboardDodger: KeyboardDodger, willResetConstraintWith transition: KeyboardDodgerTransition)
    
    /// Called when the keyboard has finished resetting its constraint to its original value.
    @objc optional func keyboardDodger(_ keyboardDodger: KeyboardDodger, didResetConstraintWith transition: KeyboardDodgerTransition)
    
    /// Called when the keyboard constraint handler needs to know whether to update its constraints with or after the keyboard has changed its frame.
    ///
    /// By default, this method returns .updateWithKeyboardChange, but for one exception:
    ///
    /// If the application's window's size class is `Regular`, but the view's size class is `Compact`, this means we're likely inside a form sheet.
    /// Then, if the keyboard is expanding, we return .updateAfterKeyboardChange, instead.
    ///
    /// This is because on an iPad, form sheets can move around underneath the keyboard while it is expanding, and so we want to defer the constraint
    /// calculation until after everything has finished moving around. Checking size classes instead of the device idiom means that split screen is handled correctly.
    @objc optional func keyboardDodger(_ keyboardDodger: KeyboardDodger, behaviorFor transition: KeyboardDodgerTransition) -> KeyboardDodgerBehavior
    
}

// MARK: - Keyboard dodger transition

/// A convenience object used for parsing the keyboard notifications.
@objc public final class KeyboardDodgerTransition: NSObject {
    
    /// Equivalent to UIKeyboardFrameBeginUserInfoKey.
    @objc public let startFrame: CGRect
    
    /// Equivalent to UIKeyboardFrameEndUserInfoKey.
    @objc public let endFrame: CGRect
    
    /// Equivalent to UIKeyboardAnimationDurationUserInfoKey.
    @objc public let animationDuration: TimeInterval
    
    /// Equivalent to UIKeyboardAnimationCurveUserInfoKey.
    @objc public let animationCurve: UIView.AnimationCurve
    
    @objc public init(startFrame: CGRect, endFrame: CGRect, animationDuration: TimeInterval, animationCurve: UIView.AnimationCurve) {
        self.startFrame = startFrame
        self.endFrame = endFrame
        self.animationDuration = animationDuration
        self.animationCurve = animationCurve
    }
    
    /// Initialise with the userInfo dictionary from UIKeyboardWillChangeFrameNotification or UIKeyboardWillHideNotification.
    @objc public convenience init?(dictionary: [AnyHashable: Any]) {
        guard let startFrame = dictionary[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else {
            return nil
        }
        
        guard let endFrame = dictionary[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return nil
        }
        
        guard let animationDuration = dictionary[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return nil
        }
        
        guard let animationCurve = (dictionary[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int).flatMap(UIView.AnimationCurve.init(rawValue:)) else {
            return nil
        }
        
        self.init(startFrame: startFrame, endFrame: endFrame, animationDuration: animationDuration, animationCurve: animationCurve)
    }
    
    /// Calculates the height of the overlap between a view and the keyboard at the start of the transition.
    ///
    /// We take the overlap rather than just the height of the keyboard, as the view doesn't always take up the full screen
    /// (e.g. a form sheet on an iPad)
    @objc public func initialConstraintHeight(for view: UIView) -> CGFloat {
        guard let frame = view.superview?.convert(view.frame, to: nil), keyboardIsDockedAtStart else {
            return 0.0
        }
        
        return frame.intersection(startFrame).height
    }
    
    /// Calculates the height of the overlap between a view and the keyboard at the end of the transition.
    ///
    /// We take the overlap rather than just the height of the keyboard, as the view doesn't always take up the full screen
    /// (e.g. a form sheet on an iPad)
    @objc public func finalConstraintHeight(for view: UIView) -> CGFloat {
        guard let frame = view.superview?.convert(view.frame, to: nil), keyboardIsDockedAtEnd else {
            return 0.0
        }
        
        return frame.intersection(endFrame).height
    }
    
    /// Calculates the height of the overlap between a view and the keyboard at the start and end of the transition, and returns whether the overlap is expanding or not.
    ///
    /// This is potentially useful to know if we want to anticipate how the constraint handler might interact with a view controller which is moving
    /// (e.g. when a form sheet on an iPad moves underneath the keyboard)
    @objc public func isExpanding(in view: UIView) -> Bool {
        return initialConstraintHeight(for: view) < finalConstraintHeight(for: view)
    }
    
    /// Calculates the height of the overlap between a view and the keyboard at the start and end of the transition, and returns whether the overlap is collapsing or not.
    ///
    /// This is potentially useful to know if we want to anticipate how the constraint handler might interact with a view controller which is moving
    /// (e.g. when a form sheet on an iPad moves underneath the keyboard)
    @objc public func isCollapsing(in view: UIView) -> Bool {
        return initialConstraintHeight(for: view) > finalConstraintHeight(for: view)
    }
    
    // MARK: Private helpers
    
    private var keyboardIsDockedAtStart: Bool {
        return UIScreen.main.bounds.maxY == startFrame.maxY
    }
    
    private var keyboardIsDockedAtEnd: Bool {
        return UIScreen.main.bounds.maxY == endFrame.maxY
    }
    
}

// MARK: - Keyboard dodger

/// Handles animating a bottom constraint for a view as the keyboard is shown/hidden/adjusted.
@objc public final class KeyboardDodger: NSObject {
    
    /// The view that contains the bottom constraint you want to manipulate when the keyboard is shown/hidden.
    @objc public let view: UIView
    
    /// The bottom constraint in the view that should adjust as the keyboard is shown/hidden.
    @objc public let constraint: NSLayoutConstraint
    
    /// The initial value for the bottom constraint in the view. Used to reset the constraint's constant back to its initial value.
    @objc private let constant: CGFloat
    
    /// The delegate is sent messages when the constraint values change.
    @objc public weak var delegate: KeyboardDodgerDelegate?
    
    /// Instantiates a KeyboardDodger. Keep a reference to this around while you want it to handle
    /// manipulating the bottom constraint of the view.
    @objc public init(view: UIView, constraint: NSLayoutConstraint, delegate: KeyboardDodgerDelegate? = nil) {
        self.view = view
        self.constraint = constraint
        self.constant = constraint.constant
        self.delegate = delegate
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let transition = KeyboardDodgerTransition(dictionary: userInfo) else {
            return
        }
        
        if behavior(for: transition) == .updateWithKeyboardChange {
            updateConstraint(with: transition)
        }
    }
    
    @objc private func keyboardDidChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let transition = KeyboardDodgerTransition(dictionary: userInfo) else {
            return
        }
        
        if behavior(for: transition) == .updateAfterKeyboardChange {
            updateConstraint(with: transition)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let transition = KeyboardDodgerTransition(dictionary: userInfo) else {
            return
        }
        
        if behavior(for: transition) == .updateWithKeyboardChange {
            resetConstraint(with: transition)
        }
    }
    
    @objc private func keyboardDidHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let transition = KeyboardDodgerTransition(dictionary: userInfo) else {
            return
        }
        
        if behavior(for: transition) == .updateAfterKeyboardChange {
            resetConstraint(with: transition)
        }
    }
    
    // MARK: Private helpers
    
    private func updateConstraint(with transition: KeyboardDodgerTransition) {
        let constant = transition.finalConstraintHeight(for: view) + self.constant
        
        guard constraint.constant != constant else {
            return
        }
        
        constraint.constant = constant
        
        delegate?.keyboardDodger?(self, willUpdateConstraintWith: transition)
        
        UIView.animate(withDuration: transition.animationDuration, delay: 0.0, options: .init(animationCurve: transition.animationCurve), animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.delegate?.keyboardDodger?(self, didUpdateConstraintWith: transition)
        }
    }
    
    private func resetConstraint(with transition: KeyboardDodgerTransition) {
        guard constraint.constant != constant else {
            return
        }
        
        constraint.constant = constant
        
        delegate?.keyboardDodger?(self, willResetConstraintWith: transition)
        UIView.animate(withDuration: transition.animationDuration, delay: 0.0, options: .init(animationCurve: transition.animationCurve), animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.delegate?.keyboardDodger?(self, didResetConstraintWith: transition)
        }
    }
    
    private func behavior(for transition: KeyboardDodgerTransition) -> KeyboardDodgerBehavior {
        if let behavior = delegate?.keyboardDodger?(self, behaviorFor: transition) {
            return behavior
        }
        
        // If we're inside a form sheet and the keyboard height is expanding, animate the text view constraints
        // only *after* the keyboard has changed, as the form sheet may move underneath the keyboard
        if view.isFullScreen == false && transition.isExpanding(in: view) {
            return .updateAfterKeyboardChange
        }
        
        return .updateWithKeyboardChange
    }
    
}

// MARK: - Private helpers

extension UITraitEnvironment {
    
    fileprivate var isFullScreen: Bool {
        guard let windowTraitCollection = UIApplication.shared.keyWindow?.traitCollection else {
            return true
        }
        
        switch (windowTraitCollection.horizontalSizeClass, traitCollection.horizontalSizeClass) {
        case (.regular, .compact):
            return false
        default:
            return true
        }
    }
    
}

extension UIView.AnimationOptions {
    
    fileprivate init(animationCurve: UIView.AnimationCurve) {
        switch animationCurve {
        case .easeInOut:
            self = .curveEaseInOut
        case .easeIn:
            self = .curveEaseIn
        case .easeOut:
            self = .curveEaseOut
        case .linear:
            self = .curveLinear
        default:
            self = .curveEaseInOut
        }
    }
    
}
