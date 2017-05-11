//
//  KeyboardConstraintHandler.h
//  TradeMeMain
//
//  Created by Stefan Church on 21/07/14.
//  Copyright (c) 2014 Trade Me. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TMUIKeyboardConstraintTransition;
@class TMUIKeyboardConstraintHandler;

/**
 *  The way the keyboard constraint handler updates its constraint.
 */
typedef NS_ENUM(NSUInteger, TMUIKeyboardConstraintHandlerBehavior) {
    
    /**
     *  The keyboard constraint handler updates its constraint while the keyboard's frame is changing.
     */
    TMUIKeyboardConstraintHandlerBehaviorUpdateWithKeyboardChange,
    
    /**
     *  The keyboard constraint handler updates its constraint after the keyboard's frame has changed.
     *  This behaviour may be desired when we don't know what the constraint is going to be until after the keyboard has moved.
     *
     *  I should describe the actual scenario that prompted this:
     *
     *  Let's say you have a form sheet view controller on an iPad in landscape mode, and you want to move its contents out of the way when you show the keyboard. When you present
     *  the keyboard, UIKit also moves the presented view controller upwards in order to maximise the space available. This is helpful, but as the view is no longer in the same place,
     *  the constraint handler's calculations are rendered incorrect. In this case it might be better to wait until after the transition before updating your constraints.
     */
    TMUIKeyboardConstraintHandlerBehaviorUpdateAfterKeyboardChange
};

/**
 *  Optional messages that can be received as the keyboard is shown/hidden.
 */
@protocol TMUIKeyboardConstraintHandlerDelegate <NSObject>

@optional

/**
 *  Called when the constraint handler is about to update its constraint.
 *
 *  @param keyboardConstraintHandler The handler managing the keyboard constraints.
 *  @param transition                A transition object, equivalent to the `userInfo` dictionary returned by the keyboard notifications.
 */
- (void)keyboardConstraintHandler:(TMUIKeyboardConstraintHandler *)keyboardConstraintHandler willUpdateConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition;

/**
 *  Called when the constraint handler has finished updating its constraint.
 *
 *  @param keyboardConstraintHandler The handler managing the keyboard constraints.
 *  @param transition                A transition object, equivalent to the `userInfo` dictionary returned by the keyboard notifications.
 */
- (void)keyboardConstraintHandler:(TMUIKeyboardConstraintHandler *)keyboardConstraintHandler didUpdateConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition;

/**
 *  Called when the keyboard is about to reset its constraint to its original value.
 *
 *  @param keyboardConstraintHandler The handler managing the keyboard constraints.
 *  @param transition                A transition object, equivalent to the `userInfo` dictionary returned by the keyboard notifications.
 */
- (void)keyboardConstraintHandler:(TMUIKeyboardConstraintHandler *)keyboardConstraintHandler willResetConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition;

/**
 *  Called when the keyboard has finished resetting its constraint to its original value.
 *
 *  @param keyboardConstraintHandler The handler managing the keyboard constraints.
 *  @param transition                A transition object, equivalent to the `userInfo` dictionary returned by the keyboard notifications.
 */
- (void)keyboardConstraintHandler:(TMUIKeyboardConstraintHandler *)keyboardConstraintHandler didResetConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition;

/**
 *  Called when the keyboard constraint handler needs to know whether to update its constraints with or after the keyboard has changed its frame.
 *
 *  By default, this method returns TMUIKeyboardConstraintHandlerBehaviorUpdateWithKeyboardChange, but for one exception:
 *
 *  If the application's window's size class is `Regular`, but the view's size class is `Compact`, this means we're likely inside a form sheet.
 *  Then, if the keyboard is expanding, we return TMUIKeyboardConstraintHandlerBehaviorUpdateAfterKeyboardChange, instead.
 *
 *  This is because on an iPad, form sheets can move around underneath the keyboard while it is expanding, and so we want to defer the constraint calculation until after everything has finished moving around. Checking size classes instead of the device idiom means that split screen is handled correctly.
 *
 *  @param keyboardConstraintHandler The handler managing the keyboard constraints.
 *  @param transition                The current transition.
 *
 *  @return behavior                 The required behavior.
 */
- (TMUIKeyboardConstraintHandlerBehavior)keyboardConstraintHandler:(TMUIKeyboardConstraintHandler *)keyboardConstraintHandler behaviorForTransition:(TMUIKeyboardConstraintTransition *)transition;

@end

/**
 *  A convenience object used for parsing the keyboard notifications.
 */
@interface TMUIKeyboardConstraintTransition : NSObject

/**
 *  Equivalent to UIKeyboardFrameBeginUserInfoKey.
 */
@property (nonatomic) CGRect startFrame;

/**
 *  Equivalent to UIKeyboardFrameEndUserInfoKey.
 */
@property (nonatomic) CGRect endFrame;

/**
 *  Equivalent to UIKeyboardAnimationDurationUserInfoKey.
 */
@property (nonatomic) NSTimeInterval animationDuration;

/**
 *  Equivalent to UIKeyboardAnimationCurveUserInfoKey.
 */
@property (nonatomic) UIViewAnimationCurve animationCurve;

/**
 *  Initialise with the userInfo dictionary from UIKeyboardWillChangeFrameNotification or UIKeyboardWillHideNotification.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 *  Calculates the height of the overlap between a view and the keyboard at the start of the transition.
 *
 *  We take the overlap rather than just the height of the keyboard, as the view doesn't always take up the full screen (e.g. a form sheet on an iPad)
 */
- (CGFloat)initialConstraintHeightForView:(UIView *)view;

/**
 *  Calculates the height of the overlap between a view and the keyboard at the end of the transition.
 *
 *  We take the overlap rather than just the height of the keyboard, as the view doesn't always take up the full screen (e.g. a form sheet on an iPad)
 */
- (CGFloat)finalConstraintHeightForView:(UIView *)view;

/**
 *  Calculates the height of the overlap between a view and the keyboard at the start and end of the transition, and returns whether the overlap is expanding or not.
 *
 *  This is potentially useful to know if we want to anticipate how the constraint handler might interact with a view controller which is moving (e.g. when a form sheet on an iPad moves underneath the keyboard)
 */
- (BOOL)isExpandingForView:(UIView *)view;

/**
 *  Calculates the height of the overlap between a view and the keyboard at the start and end of the transition, and returns whether the overlap is collapsing or not.
 *
 *  This is potentially useful to know if we want to anticipate how the constraint handler might interact with a view controller which is moving (e.g. when a form sheet on an iPad moves underneath the keyboard)
 */
- (BOOL)isCollapsingForView:(UIView *)view;

@end

/**
 *  Handles animating a bottom constraint for a view as the keyboard is shown/hidden/adjusted
 */
@interface TMUIKeyboardConstraintHandler : NSObject

/**
 *  The view that contains the bottom constraint you want to manipulate when the keyboard is shown/hidden.
 */
@property (readonly) UIView *view;

/**
 *  The bottom constraint in the view that should adjust as the keyboard is shown/hidden.
 */
@property (readonly) NSLayoutConstraint *constraintBottom;

/**
 *  The delegate is sent messages when the constraint values change.
 */
@property (weak, nonatomic) id<TMUIKeyboardConstraintHandlerDelegate> delegate;

/**
 *  Instantiates a TMUIKeyboardConstraintHandler. Keep a reference to this around while you want it to handle 
 *  manipulating the bottom constraint of the view.
 *
 *  @param view             The view that contains the bottom constraint you want to manipulate when the keyboard is shown/hidden.
 *  @param bottomConstraint The bottom constraint in the view that should adjust as the keyboard is shown/hidden.
 *
 *  @return An instance of TMUIKeyboardConstraintHandler
 */
- (instancetype)initWithView:(UIView *)view bottomConstraint:(NSLayoutConstraint *)bottomConstraint;

/**
 *  Instantiates a TMUIKeyboardConstraintHandler. Keep a reference to this around while you want it to handle
 *  manipulating the bottom constraint of the view.
 *
 *  @param view             The view that contains the bottom constraint you want to manipulate when the keyboard is shown/hidden.
 *  @param bottomConstraint The bottom constraint in the view that should adjust as the keyboard is shown/hidden.
 *  @param delegate         The delegate
 *
 *  @return An instance of TMUIKeyboardConstraintHandler
 */
- (instancetype)initWithView:(UIView *)view bottomConstraint:(NSLayoutConstraint *)bottomConstraint delegate:(id<TMUIKeyboardConstraintHandlerDelegate>)delegate;

@end
