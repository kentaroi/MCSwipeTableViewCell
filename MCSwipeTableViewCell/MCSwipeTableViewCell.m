//
//  MCSwipeTableViewCell.m
//  MCSwipeTableViewCell
//
//  Created by Ali Karagoz on 24/02/13.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

#import "MCSwipeTableViewCell.h"

static CGFloat const kMCStop1                       = 0.25; // Percentage limit to trigger the first action
static CGFloat const kMCStop2                       = 0.75; // Percentage limit to trigger the second action
static CGFloat const kMCStop3                       = 0.90;
static CGFloat const kMCBounceAmplitude             = 20.0; // Maximum bounce amplitude when using the MCSwipeTableViewCellModeSwitch mode
static CGFloat const kMCDamping                     = 0.6;  // Damping of the spring animation
static CGFloat const kMCVelocity                    = 0.9;  // Velocity of the spring animation
static CGFloat const kMCAnimationDuration           = 0.4;  // Duration of the animation
static NSTimeInterval const kMCBounceDuration1      = 0.2;  // Duration of the first part of the bounce animation
static NSTimeInterval const kMCBounceDuration2      = 0.1;  // Duration of the second part of the bounce animation
static NSTimeInterval const kMCDurationLowLimit     = 0.25; // Lowest duration when swiping the cell because we try to simulate velocity
static NSTimeInterval const kMCDurationHighLimit    = 0.1;  // Highest duration when swiping the cell because we try to simulate velocity

typedef NS_ENUM(NSUInteger, MCSwipeTableViewCellDirection) {
    MCSwipeTableViewCellDirectionLeft = 0,
    MCSwipeTableViewCellDirectionCenter,
    MCSwipeTableViewCellDirectionRight
};

@interface MCSwipeTableViewCell () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) MCSwipeTableViewCellDirection direction;
@property (nonatomic, assign) CGFloat currentPercentage;
@property (nonatomic, assign) BOOL isExited;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIImageView *contentScreenshotView;
@property (nonatomic, strong) UIView *colorIndicatorView;
@property (nonatomic, strong) UIView *slidingView;
@property (nonatomic, strong) UIView *activeView;

// Initialization
- (void)initializer;
- (void)initDefaults;

// View Manipulation.
- (void)setupSwipingView;
- (void)uninstallSwipingView;
- (void)setViewOfSlidingView:(UIView *)slidingView;

// Percentage
- (CGFloat)offsetWithPercentage:(CGFloat)percentage relativeToWidth:(CGFloat)width;
- (CGFloat)percentageWithOffset:(CGFloat)offset relativeToWidth:(CGFloat)width;
- (NSTimeInterval)animationDurationWithVelocity:(CGPoint)velocity;
- (MCSwipeTableViewCellDirection)directionWithPercentage:(CGFloat)percentage;
- (UIView *)viewWithPercentage:(CGFloat)percentage;
- (CGFloat)alphaWithPercentage:(CGFloat)percentage;
- (UIColor *)colorWithPercentage:(CGFloat)percentage;
- (MCSwipeTableViewCellState)stateWithPercentage:(CGFloat)percentage;

// Movement
- (void)animateWithOffset:(CGFloat)offset;
- (void)slideViewWithPercentage:(CGFloat)percentage view:(UIView *)view isDragging:(BOOL)isDragging;
- (void)moveWithDuration:(NSTimeInterval)duration andDirection:(MCSwipeTableViewCellDirection)direction;

// Utilities
- (UIImage *)imageWithView:(UIView *)view;

// Completion block.
- (void)executeCompletionBlock;

@end

@implementation MCSwipeTableViewCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initializer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializer];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    
    [self initDefaults];
    
    // Setup Gesture Recognizer.
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    _panGestureRecognizer.delegate = self;
}

- (void)initDefaults {
    
    _isExited = NO;
    _dragging = NO;
    _shouldDrag = YES;
    _shouldAnimateIcons = YES;
    
    _rightFirstTrigger  = kMCStop1;
    _rightSecondTrigger = kMCStop2;
    _rightThirdTrigger = kMCStop3;
    _leftFirstTrigger   = kMCStop1;
    _leftSecondTrigger  = kMCStop2;
    _leftThirdTrigger  = kMCStop3;
    
    _damping = kMCDamping;
    _velocity = kMCVelocity;
    _animationDuration = kMCAnimationDuration;
    
    _defaultColor = [UIColor whiteColor];
    
    _modeForStateR1 = MCSwipeTableViewCellModeNone;
    _modeForStateR2 = MCSwipeTableViewCellModeNone;
    _modeForStateR3 = MCSwipeTableViewCellModeNone;
    _modeForStateL1 = MCSwipeTableViewCellModeNone;
    _modeForStateL2 = MCSwipeTableViewCellModeNone;
    _modeForStateL3 = MCSwipeTableViewCellModeNone;
    
    _colorR1 = nil;
    _colorR2 = nil;
    _colorR3 = nil;
    _colorL1 = nil;
    _colorL2 = nil;
    _colorL3 = nil;
    
    _activeView = nil;
    _viewR1 = nil;
    _viewR2 = nil;
    _viewR3 = nil;
    _viewL1 = nil;
    _viewL2 = nil;
    _viewL3 = nil;
}

#pragma mark - Prepare reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self uninstallSwipingView];
    [self initDefaults];
}

#pragma mark - View Manipulation

- (void)setupSwipingView {
    if (_contentScreenshotView) {
        return;
    }
    
    // If the content view background is transparent we get the background color.
    BOOL isContentViewBackgroundClear = !self.contentView.backgroundColor;
    if (isContentViewBackgroundClear) {
        BOOL isBackgroundClear = [self.backgroundColor isEqual:[UIColor clearColor]];
        self.contentView.backgroundColor = isBackgroundClear ? [UIColor whiteColor] :self.backgroundColor;
    }
    
    UIImage *contentViewScreenshotImage = [self imageWithView:self];
    
    if (isContentViewBackgroundClear) {
        self.contentView.backgroundColor = nil;
    }
    
    _colorIndicatorView = [[UIView alloc] initWithFrame:self.bounds];
    _colorIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    _colorIndicatorView.backgroundColor = self.defaultColor ? self.defaultColor : [UIColor clearColor];
    [self addSubview:_colorIndicatorView];
    
    _slidingView = [[UIView alloc] init];
    _slidingView.contentMode = UIViewContentModeCenter;
    [_colorIndicatorView addSubview:_slidingView];
    
    _contentScreenshotView = [[UIImageView alloc] initWithImage:contentViewScreenshotImage];
    [self addSubview:_contentScreenshotView];
}

- (void)uninstallSwipingView {
    if (!_contentScreenshotView) {
        return;
    }
    
    [_slidingView removeFromSuperview];
    _slidingView = nil;
    
    [_colorIndicatorView removeFromSuperview];
    _colorIndicatorView = nil;
    
    [_contentScreenshotView removeFromSuperview];
    _contentScreenshotView = nil;
}

- (void)setViewOfSlidingView:(UIView *)slidingView {
    if (!_slidingView) {
        return;
    }
    
    NSArray *subviews = [_slidingView subviews];
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
    }];
    
    [_slidingView addSubview:slidingView];
}

#pragma mark - Swipe configuration

- (CGFloat)firstTrigger {
    if (_rightFirstTrigger != _leftFirstTrigger)
        return CGFLOAT_MAX;

    return _rightFirstTrigger;
}

- (void)setFirstTrigger:(CGFloat)trigger {
    _rightFirstTrigger = trigger;
    _leftFirstTrigger = trigger;
}

- (CGFloat)secondTrigger {
    if (_rightSecondTrigger != _leftSecondTrigger)
        return CGFLOAT_MAX;

    return _rightSecondTrigger;
}

- (void)setSecondTrigger:(CGFloat)trigger {
    _rightSecondTrigger = trigger;
    _leftSecondTrigger = trigger;
}

- (CGFloat)thirdTrigger {
    if (_rightThirdTrigger != _leftThirdTrigger)
        return CGFLOAT_MAX;

    return _rightThirdTrigger;
}

- (void)setThirdTrigger:(CGFloat)trigger {
    _rightThirdTrigger = trigger;
    _leftThirdTrigger = trigger;
}

- (NSArray<NSNumber *> *)rightTriggers {
    return @[@(_rightFirstTrigger), @(_rightSecondTrigger), @(_rightThirdTrigger)];
}

- (void)setRightTriggers:(NSArray<NSNumber *> *)triggers {
    NSUInteger numberOfTriggers = triggers.count > 3 ? 3 : triggers.count;
    switch (numberOfTriggers) {
        case 3:
            _rightThirdTrigger = (CGFloat)triggers[2].doubleValue;
        case 2:
            _rightSecondTrigger = (CGFloat)triggers[1].doubleValue;
        case 1:
            _rightFirstTrigger = (CGFloat)triggers[0].doubleValue;
    }
}

- (NSArray<NSNumber *> *)leftTriggers {
    return @[@(_leftFirstTrigger), @(_leftSecondTrigger), @(_leftThirdTrigger)];
}

- (void)setLeftTriggers:(NSArray<NSNumber *> *)triggers {
    NSUInteger numberOfTriggers = triggers.count > 3 ? 3 : triggers.count;
    switch (numberOfTriggers) {
        case 3:
            _leftThirdTrigger = (CGFloat)triggers[2].doubleValue;
        case 2:
            _leftSecondTrigger = (CGFloat)triggers[1].doubleValue;
        case 1:
            _leftFirstTrigger = (CGFloat)triggers[0].doubleValue;
    }
}

- (void)setSwipeGestureWithView:(UIView *)view
                          color:(UIColor *)color
                           mode:(MCSwipeTableViewCellMode)mode
                          state:(MCSwipeTableViewCellState)state
                completionBlock:(MCSwipeCompletionBlock)completionBlock {
    
    NSParameterAssert(view);
    NSParameterAssert(color);
    
    // Depending on the state we assign the attributes
    if ((state & MCSwipeTableViewCellStateRight1) == MCSwipeTableViewCellStateRight1) {
        _completionBlockR1 = completionBlock;
        _viewR1 = view;
        _colorR1 = color;
        _modeForStateR1 = mode;
    }
    
    if ((state & MCSwipeTableViewCellStateRight2) == MCSwipeTableViewCellStateRight2) {
        _completionBlockR2 = completionBlock;
        _viewR2 = view;
        _colorR2 = color;
        _modeForStateR2 = mode;
    }
    
    if ((state & MCSwipeTableViewCellStateRight3) == MCSwipeTableViewCellStateRight3) {
        _completionBlockR3 = completionBlock;
        _viewR3 = view;
        _colorR3 = color;
        _modeForStateR3 = mode;
    }
    
    if ((state & MCSwipeTableViewCellStateLeft1) == MCSwipeTableViewCellStateLeft1) {
        _completionBlockL1 = completionBlock;
        _viewL1 = view;
        _colorL1 = color;
        _modeForStateL1 = mode;
    }

    if ((state & MCSwipeTableViewCellStateLeft2) == MCSwipeTableViewCellStateLeft2) {
        _completionBlockL2 = completionBlock;
        _viewL2 = view;
        _colorL2 = color;
        _modeForStateL2= mode;
    }

    if ((state & MCSwipeTableViewCellStateLeft3) == MCSwipeTableViewCellStateLeft3) {
        _completionBlockL3 = completionBlock;
        _viewL3 = view;
        _colorL3 = color;
        _modeForStateL3= mode;
    }
}

#pragma mark - Handle Gestures

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture {
    
    if (![self shouldDrag] || _isExited) {
        return;
    }
    
    UIGestureRecognizerState state      = [gesture state];
    CGPoint translation                 = [gesture translationInView:self];
    CGPoint velocity                    = [gesture velocityInView:self];
    CGFloat percentage                  = [self percentageWithOffset:CGRectGetMinX(_contentScreenshotView.frame) relativeToWidth:CGRectGetWidth(self.bounds)];
    NSTimeInterval animationDuration    = [self animationDurationWithVelocity:velocity];
    _direction                          = [self directionWithPercentage:percentage];
    
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        _dragging = YES;
        
        [self setupSwipingView];
        
        CGPoint center = {_contentScreenshotView.center.x + translation.x, _contentScreenshotView.center.y};
        _contentScreenshotView.center = center;
        [self animateWithOffset:CGRectGetMinX(_contentScreenshotView.frame)];
        [gesture setTranslation:CGPointZero inView:self];
        
        // Notifying the delegate that we are dragging with an offset percentage.
        if ([_delegate respondsToSelector:@selector(swipeTableViewCell:didSwipeWithPercentage:)]) {
            [_delegate swipeTableViewCell:self didSwipeWithPercentage:percentage];
        }
    }
    
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        
        _dragging = NO;
        _activeView = [self viewWithPercentage:percentage];
        _currentPercentage = percentage;
        
        MCSwipeTableViewCellState cellState = [self stateWithPercentage:percentage];
        MCSwipeTableViewCellMode cellMode = MCSwipeTableViewCellModeNone;
        
        if (cellState == MCSwipeTableViewCellStateRight1 && _modeForStateR1) {
            cellMode = self.modeForStateR1;
        }
        
        else if (cellState == MCSwipeTableViewCellStateRight2 && _modeForStateR2) {
            cellMode = self.modeForStateR2;
        }
        
        else if (cellState == MCSwipeTableViewCellStateRight3 && _modeForStateR3) {
            cellMode = self.modeForStateR3;
        }
        
        else if (cellState == MCSwipeTableViewCellStateLeft1 && _modeForStateL1) {
            cellMode = self.modeForStateL1;
        }

        else if (cellState == MCSwipeTableViewCellStateLeft2 && _modeForStateL2) {
            cellMode = self.modeForStateL2;
        }

        else if (cellState == MCSwipeTableViewCellStateLeft3 && _modeForStateL3) {
            cellMode = self.modeForStateL3;
        }
        
        if (cellMode == MCSwipeTableViewCellModeExit && _direction != MCSwipeTableViewCellDirectionCenter) {
            [self moveWithDuration:animationDuration andDirection:_direction];
        }
        
        else {
            [self swipeToOriginWithCompletion:^{
                [self executeCompletionBlock];
            }];
        }
        
        // We notify the delegate that we just ended swiping.
        if ([_delegate respondsToSelector:@selector(swipeTableViewCellDidEndSwiping:)]) {
            [_delegate swipeTableViewCellDidEndSwiping:self];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if ([gestureRecognizer class] == [UIPanGestureRecognizer class]) {
        
        UIPanGestureRecognizer *g = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint point = [g velocityInView:self];
        
        if (fabs(point.x) > fabs(point.y) ) {
            if (point.x < 0 && !_modeForStateL1 && !_modeForStateL2 && !_modeForStateL3) {
                return NO;
            }
            
            if (point.x > 0 && !_modeForStateR1 && !_modeForStateR2 && !_modeForStateR3) {
                return NO;
            }
            
            // We notify the delegate that we just started dragging
            if ([_delegate respondsToSelector:@selector(swipeTableViewCellDidStartSwiping:)]) {
                [_delegate swipeTableViewCellDidStartSwiping:self];
            }
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Percentage

- (CGFloat)offsetWithPercentage:(CGFloat)percentage relativeToWidth:(CGFloat)width {
    CGFloat offset = percentage * width;
    
    if (offset < -width) offset = -width;
    else if (offset > width) offset = width;
    
    return offset;
}

- (CGFloat)percentageWithOffset:(CGFloat)offset relativeToWidth:(CGFloat)width {
    CGFloat percentage = offset / width;
    
    if (percentage < -1.0) percentage = -1.0;
    else if (percentage > 1.0) percentage = 1.0;
    
    return percentage;
}

- (NSTimeInterval)animationDurationWithVelocity:(CGPoint)velocity {
    CGFloat width                           = CGRectGetWidth(self.bounds);
    NSTimeInterval animationDurationDiff    = kMCDurationHighLimit - kMCDurationLowLimit;
    CGFloat horizontalVelocity              = velocity.x;
    
    if (horizontalVelocity < -width) horizontalVelocity = -width;
    else if (horizontalVelocity > width) horizontalVelocity = width;
    
    return (kMCDurationHighLimit + kMCDurationLowLimit) - fabs(((horizontalVelocity / width) * animationDurationDiff));
}

- (MCSwipeTableViewCellDirection)directionWithPercentage:(CGFloat)percentage {
    if (percentage < 0) {
        return MCSwipeTableViewCellDirectionLeft;
    }
    
    else if (percentage > 0) {
        return MCSwipeTableViewCellDirectionRight;
    }
    
    else {
        return MCSwipeTableViewCellDirectionCenter;
    }
}

- (UIView *)viewWithPercentage:(CGFloat)percentage {
    
    UIView *view;

    if (percentage >= 0) {
        if (_modeForStateR3 && percentage >= _rightThirdTrigger) {
            view = _viewR3;
        } else if (_modeForStateR2 && percentage >= _rightSecondTrigger) {
            view = _viewR2;
        } else if (_modeForStateR1) {
            view = _viewR1;
        }
    } else {
        if (_modeForStateL3 && percentage <= -_leftThirdTrigger) {
            view = _viewL3;
        } else if (_modeForStateL2 && percentage <= -_leftSecondTrigger) {
            view = _viewL2;
        } else if (_modeForStateL1) {
            view = _viewL1;
        }
    }
    
    return view;
}

- (CGFloat)alphaWithPercentage:(CGFloat)percentage {
    CGFloat alpha;
    
    if (percentage >= 0 && percentage < _rightFirstTrigger) {
        alpha = percentage / _rightFirstTrigger;
    }
    
    else if (percentage < 0 && percentage > -_leftFirstTrigger) {
        alpha = fabs(percentage / _leftFirstTrigger);
    }
    
    else {
        alpha = 1.0;
    }
    
    return alpha;
}

- (UIColor *)colorWithPercentage:(CGFloat)percentage {
    UIColor *color;
    
    // Background Color
    
    color = self.defaultColor ? self.defaultColor : [UIColor clearColor];
    
    if (percentage > _rightFirstTrigger) {
        if (_modeForStateR3 && percentage > _rightThirdTrigger) {
            color = _colorR3;
        } else if (_modeForStateR2 && percentage > _rightSecondTrigger) {
            color = _colorR2;
        } else if (_modeForStateR1) {
            color = _colorR1;
        }
    } else if (percentage < -_leftFirstTrigger) {
        if (_modeForStateL3 && percentage < -_leftThirdTrigger) {
            color = _colorL3;
        } else if (_modeForStateL2 && percentage < -_leftSecondTrigger) {
            color = _colorL2;
        } else if (_modeForStateL1) {
            color = _colorL1;
        }
    }
    
    return color;
}

- (MCSwipeTableViewCellState)stateWithPercentage:(CGFloat)percentage {
    MCSwipeTableViewCellState state;
    
    state = MCSwipeTableViewCellStateNone;
    
    if (percentage >= _rightFirstTrigger) {
        if (_modeForStateR3 && percentage >= _rightThirdTrigger) {
            state = MCSwipeTableViewCellStateRight3;
        } else if (_modeForStateR2 && percentage >= _rightSecondTrigger) {
            state = MCSwipeTableViewCellStateRight2;
        } else if (_modeForStateR1) {
            state = MCSwipeTableViewCellStateRight1;
        }
    } else if (percentage <= -_leftFirstTrigger) {
        if (_modeForStateL3 && percentage <= -_leftThirdTrigger) {
            state = MCSwipeTableViewCellStateLeft3;
        } else if (_modeForStateL2 && percentage <= -_leftSecondTrigger) {
            state = MCSwipeTableViewCellStateLeft2;
        } else if (_modeForStateL1) {
            state = MCSwipeTableViewCellStateLeft1;
        }
    }
    
    return state;
}

#pragma mark - Movement

- (void)animateWithOffset:(CGFloat)offset {
    CGFloat percentage = [self percentageWithOffset:offset relativeToWidth:CGRectGetWidth(self.bounds)];
    
    UIView *view = [self viewWithPercentage:percentage];
    
    // View Position.
    if (view) {
        [self setViewOfSlidingView:view];
        _slidingView.alpha = [self alphaWithPercentage:percentage];
        [self slideViewWithPercentage:percentage view:view isDragging:self.shouldAnimateIcons];
    }
    
    // Color
    UIColor *color = [self colorWithPercentage:percentage];
    if (color != nil) {
        _colorIndicatorView.backgroundColor = color;
    }
}

- (void)slideViewWithPercentage:(CGFloat)percentage view:(UIView *)view isDragging:(BOOL)isDragging {
    if (!view) {
        return;
    }
    
    CGFloat threshold = 0.25;
    CGPoint position = CGPointZero;
    position.y = CGRectGetHeight(self.bounds) / 2.0;
    
    if (isDragging) {
        if (percentage >= 0 && percentage < threshold) {
            position.x = [self offsetWithPercentage:(percentage / 2) relativeToWidth:CGRectGetWidth(self.bounds)];
        }
        
        else if (percentage >= threshold) {
            position.x = [self offsetWithPercentage:percentage - (threshold / 2) relativeToWidth:CGRectGetWidth(self.bounds)];
        }
        
        else if (percentage < 0 && percentage >= -threshold) {
            position.x = CGRectGetWidth(self.bounds) - [self offsetWithPercentage:(-percentage / 2) relativeToWidth:CGRectGetWidth(self.bounds)];
        }
        
        else if (percentage < -threshold) {
            position.x = CGRectGetWidth(self.bounds) + [self offsetWithPercentage:percentage + (threshold / 2) relativeToWidth:CGRectGetWidth(self.bounds)];
        }
    }
    
    else {
        if (_direction == MCSwipeTableViewCellDirectionRight) {
        }
        
        else if (_direction == MCSwipeTableViewCellDirectionLeft) {
            position.x = CGRectGetWidth(self.bounds);
        }
        
        else {
            return;
        }
    }
    
    CGSize activeViewSize = view.bounds.size;
    CGRect activeViewFrame = CGRectMake(position.x - activeViewSize.width / 2.0,
                                        position.y - activeViewSize.height / 2.0,
                                        activeViewSize.width,
                                        activeViewSize.height);
    
    activeViewFrame = CGRectIntegral(activeViewFrame);
    _slidingView.frame = activeViewFrame;
}

- (void)moveWithDuration:(NSTimeInterval)duration andDirection:(MCSwipeTableViewCellDirection)direction {
    
    _isExited = YES;
    CGFloat origin;
    
    if (direction == MCSwipeTableViewCellDirectionLeft) {
        origin = -CGRectGetWidth(self.bounds);
    }
    
    else if (direction == MCSwipeTableViewCellDirectionRight) {
        origin = CGRectGetWidth(self.bounds);
    }
    
    else {
        origin = 0;
    }
    
    CGFloat percentage = [self percentageWithOffset:origin relativeToWidth:CGRectGetWidth(self.bounds)];
    CGRect frame = _contentScreenshotView.frame;
    frame.origin.x = origin;
    
    // Color
    UIColor *color = [self colorWithPercentage:_currentPercentage];
    if (color) {
        [_colorIndicatorView setBackgroundColor:color];
    }
    
    [UIView animateWithDuration:duration delay:0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction) animations:^{
        _contentScreenshotView.frame = frame;
        _slidingView.alpha = 0;
        [self slideViewWithPercentage:percentage view:_activeView isDragging:self.shouldAnimateIcons];
    } completion:^(BOOL finished) {
        [self executeCompletionBlock];
    }];
}

- (void)swipeToOriginWithCompletion:(void(^)(void))completion {
    CGFloat bounceDistance = kMCBounceAmplitude * _currentPercentage;
    
    if ([UIView.class respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
        
        [UIView animateWithDuration:_animationDuration delay:0.0 usingSpringWithDamping:_damping initialSpringVelocity:_velocity options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            CGRect frame = _contentScreenshotView.frame;
            frame.origin.x = 0;
            _contentScreenshotView.frame = frame;
            
            // Clearing the indicator view
            _colorIndicatorView.backgroundColor = self.defaultColor;
            
            _slidingView.alpha = 0;
            [self slideViewWithPercentage:0 view:_activeView isDragging:NO];
            
        } completion:^(BOOL finished) {
            
            _isExited = NO;
            [self uninstallSwipingView];
            
            if (completion) {
                completion();
            }
        }];
    }
    
    else {
        [UIView animateWithDuration:kMCBounceDuration1 delay:0 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            
            CGRect frame = _contentScreenshotView.frame;
            frame.origin.x = -bounceDistance;
            _contentScreenshotView.frame = frame;
            
            _slidingView.alpha = 0;
            [self slideViewWithPercentage:0 view:_activeView isDragging:NO];
            
            // Setting back the color to the default.
            _colorIndicatorView.backgroundColor = self.defaultColor;
            
        } completion:^(BOOL finished1) {
            
            [UIView animateWithDuration:kMCBounceDuration2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                
                CGRect frame = _contentScreenshotView.frame;
                frame.origin.x = 0;
                _contentScreenshotView.frame = frame;
                
                // Clearing the indicator view
                _colorIndicatorView.backgroundColor = [UIColor clearColor];
                
            } completion:^(BOOL finished2) {
                
                _isExited = NO;
                [self uninstallSwipingView];
                
                if (completion) {
                    completion();
                }
            }];
        }];
    }
}

#pragma mark - Utilities

- (UIImage *)imageWithView:(UIView *)view {
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Completion block

- (void)executeCompletionBlock {
    MCSwipeTableViewCellState state = [self stateWithPercentage:_currentPercentage];
    MCSwipeTableViewCellMode mode = MCSwipeTableViewCellModeNone;
    MCSwipeCompletionBlock completionBlock;
    
    switch (state) {
        case MCSwipeTableViewCellStateRight1: {
            mode = self.modeForStateR1;
            completionBlock = _completionBlockR1;
        } break;
            
        case MCSwipeTableViewCellStateRight2: {
            mode = self.modeForStateR2;
            completionBlock = _completionBlockR2;
        } break;
            
        case MCSwipeTableViewCellStateRight3: {
            mode = self.modeForStateR3;
            completionBlock = _completionBlockR3;
        } break;
            
        case MCSwipeTableViewCellStateLeft1: {
            mode = self.modeForStateL1;
            completionBlock = _completionBlockL1;
        } break;

        case MCSwipeTableViewCellStateLeft2: {
            mode = self.modeForStateL2;
            completionBlock = _completionBlockL2;
        } break;

        case MCSwipeTableViewCellStateLeft3: {
            mode = self.modeForStateL3;
            completionBlock = _completionBlockL3;
        } break;
            
        default:
            break;
    }
    
    if (completionBlock) {
        completionBlock(self, state, mode);
    }
    
}

@end
