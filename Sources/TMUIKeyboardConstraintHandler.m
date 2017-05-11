//
//  KeyboardConstraintHandler.m
//  TradeMeMain
//
//  Created by Stefan Church on 21/07/14.
//  Copyright (c) 2014 Trade Me. All rights reserved.
//

#import "TMUIKeyboardConstraintHandler.h"

#import <TMUILibrary/UIView+TMUIAdditions.h>

#import <TMUILibrary/TMUILibrary-Swift.h>

@interface TMUIKeyboardConstraintHandler ()

@property (nonatomic) CGFloat initialConstant;

@end

@implementation TMUIKeyboardConstraintTransition

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _startFrame = [dictionary[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        _endFrame = [dictionary[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        _animationDuration = [dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        _animationCurve = [dictionary[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    }
    return self;
}

- (CGFloat)initialConstraintHeightForView:(UIView *)view {
    if ([self keyboardIsDockedAtStart]) {
        CGRect viewFrame = [view.superview convertRect:view.frame toView:nil];
        return CGRectGetHeight(CGRectIntersection(self.startFrame, viewFrame));
    }
    return 0.0;
}

- (CGFloat)finalConstraintHeightForView:(UIView *)view {
    if ([self keyboardIsDockedAtEnd]) {
        CGRect viewFrame = [view.superview convertRect:view.frame toView:nil];
        return CGRectGetHeight(CGRectIntersection(self.endFrame, viewFrame));
    }
    return 0.0;
}

- (BOOL)isExpandingForView:(UIView *)view {
    CGFloat initialConstraintHeight = [self initialConstraintHeightForView:view];
    CGFloat finalConstraintHeight = [self finalConstraintHeightForView:view];
    
    return initialConstraintHeight < finalConstraintHeight;
}

- (BOOL)isCollapsingForView:(UIView *)view {
    CGFloat initialConstraintHeight = [self initialConstraintHeightForView:view];
    CGFloat finalConstraintHeight = [self finalConstraintHeightForView:view];
    
    return initialConstraintHeight > finalConstraintHeight;
}

- (BOOL)keyboardIsDockedAtStart {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    return CGRectGetMaxY(screenBounds) == CGRectGetMaxY(self.startFrame);
}

- (BOOL)keyboardIsDockedAtEnd {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    return CGRectGetMaxY(screenBounds) == CGRectGetMaxY(self.endFrame);
}

@end

@implementation TMUIKeyboardConstraintHandler

#pragma mark -
- (instancetype)initWithView:(UIView *)view bottomConstraint:(NSLayoutConstraint *)bottomConstraint {
    return [self initWithView:view bottomConstraint:bottomConstraint delegate:nil];
}

- (instancetype)initWithView:(UIView *)view bottomConstraint:(NSLayoutConstraint *)bottomConstraint delegate:(id<TMUIKeyboardConstraintHandlerDelegate>)delegate {
    self = [super init];
    if (self) {
        _view = view;
        _constraintBottom = bottomConstraint;
        _initialConstant = bottomConstraint.constant;
        _delegate = delegate;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard notificaion handlers
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    TMUIKeyboardConstraintTransition *transition = [[TMUIKeyboardConstraintTransition alloc] initWithDictionary:notification.userInfo];
    
    if ([self behaviorForTransition:transition] == TMUIKeyboardConstraintHandlerBehaviorUpdateWithKeyboardChange) {
        [self updateConstraintWithTransition:transition];
    }
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification {
    TMUIKeyboardConstraintTransition *transition = [[TMUIKeyboardConstraintTransition alloc] initWithDictionary:notification.userInfo];
    
    if ([self behaviorForTransition:transition] == TMUIKeyboardConstraintHandlerBehaviorUpdateAfterKeyboardChange) {
        [self updateConstraintWithTransition:transition];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    TMUIKeyboardConstraintTransition *transition = [[TMUIKeyboardConstraintTransition alloc] initWithDictionary:notification.userInfo];
    
    if ([self behaviorForTransition:transition] == TMUIKeyboardConstraintHandlerBehaviorUpdateWithKeyboardChange) {
        [self resetConstraintWithTransition:transition];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    TMUIKeyboardConstraintTransition *transition = [[TMUIKeyboardConstraintTransition alloc] initWithDictionary:notification.userInfo];
    
    if ([self behaviorForTransition:transition] == TMUIKeyboardConstraintHandlerBehaviorUpdateAfterKeyboardChange) {
        [self resetConstraintWithTransition:transition];
    }
}

#pragma mark - Constraint updating

- (void)updateConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    CGFloat newConstant = [transition finalConstraintHeightForView:self.view] + self.initialConstant;
    
    if (self.constraintBottom.constant == newConstant) {
        return;
    }
    
    self.constraintBottom.constant = newConstant;
    
    [self willUpdateConstraintWithTransition:transition];
    [UIView animateWithDuration:transition.animationDuration delay:0.0f options:[UIView UIViewAnimationOptionForCurve:transition.animationCurve] animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self didUpdateConstraintWithTransition:transition];
    }];
}

- (void)resetConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    if (self.constraintBottom.constant == self.initialConstant) {
        return;
    }
    
    self.constraintBottom.constant = self.initialConstant;
    
    [self willResetConstraintWithTransition:transition];
    [UIView animateWithDuration:transition.animationDuration delay:0.0f options:[UIView UIViewAnimationOptionForCurve:transition.animationCurve] animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self didResetConstraintWithTransition:transition];
    }];
}

#pragma mark - Delegate events

- (void)willUpdateConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    if ([self.delegate respondsToSelector:@selector(keyboardConstraintHandler:willUpdateConstraintWithTransition:)]) {
        [self.delegate keyboardConstraintHandler:self willUpdateConstraintWithTransition:transition];
    }
}

- (void)didUpdateConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    if ([self.delegate respondsToSelector:@selector(keyboardConstraintHandler:didUpdateConstraintWithTransition:)]) {
        [self.delegate keyboardConstraintHandler:self didUpdateConstraintWithTransition:transition];
    }
}

- (void)willResetConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    if ([self.delegate respondsToSelector:@selector(keyboardConstraintHandler:willResetConstraintWithTransition:)]) {
        [self.delegate keyboardConstraintHandler:self willResetConstraintWithTransition:transition];
    }
}

- (void)didResetConstraintWithTransition:(TMUIKeyboardConstraintTransition *)transition {
    if ([self.delegate respondsToSelector:@selector(keyboardConstraintHandler:didResetConstraintWithTransition:)]) {
        [self.delegate keyboardConstraintHandler:self didResetConstraintWithTransition:transition];
    }
}
            
#pragma mark - Delegate getters

- (TMUIKeyboardConstraintHandlerBehavior)behaviorForTransition:(TMUIKeyboardConstraintTransition *)transition {
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardConstraintHandler:behaviorForTransition:)]) {
        return [self.delegate keyboardConstraintHandler:self behaviorForTransition:transition];
    }
    
    //-- If we're inside a form sheet and the keyboard height is expanding, animate the text view constraints only *after* the keyboard has changed, as the form sheet may move underneath the keyboard
    if (self.view.tme_isNotFullScreen && [transition isExpandingForView:self.view]) {
        return TMUIKeyboardConstraintHandlerBehaviorUpdateAfterKeyboardChange;
    }
    
    return TMUIKeyboardConstraintHandlerBehaviorUpdateWithKeyboardChange;
}

@end
