//
//  MCSwipeTableViewCell.h
//  MCSwipeTableViewCell
//
//  Created by Ali Karagoz on 24/02/13.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCSwipeTableViewCell;

/** Describes the state that has been triggered by the user. */
typedef NS_OPTIONS(NSUInteger, MCSwipeTableViewCellState) {

    /** No state has been triggered. */
    MCSwipeTableViewCellStateNone = 0,
    
    /** 1st state triggered during a Left -> Right swipe. */
    MCSwipeTableViewCellStateRight1 = (1 << 0),
    MCSwipeTableViewCellStateFromoLeft1 = (1 << 0),

    /** 2nd state triggered during a Left -> Right swipe. */
    MCSwipeTableViewCellStateRight2 = (1 << 1),
    MCSwipeTableViewCellStateFromoLeft2 = (1 << 1),

    /** 3rd state triggered during a Left -> Right swipe. */
    MCSwipeTableViewCellStateRight3 = (1 << 4),
    MCSwipeTableViewCellStateFromoLeft3 = (1 << 4),

    // Disabled, but reserved for possible future use
    // /** 4th state triggered during a Left -> Right swipe. */
    // MCSwipeTableViewCellStateRight4 = (1 << 5),
    // MCSwipeTableViewCellStateFromoLeft4 = (1 << 5),

    /** 1st state triggered during a Right -> Left swipe. */
    MCSwipeTableViewCellStateLeft1 = (1 << 2),
    MCSwipeTableViewCellStateFromRight1 = (1 << 2),

    /** 2nd state triggered during a Right -> Left swipe. */
    MCSwipeTableViewCellStateLeft2 = (1 << 3),
    MCSwipeTableViewCellStateFromRight2 = (1 << 3),

    /** 3rd state triggered during a Right -> Left swipe. */
    MCSwipeTableViewCellStateLeft3 = (1 << 6),
    MCSwipeTableViewCellStateFromRight3 = (1 << 6),

    // Disabled, but reserved for possible future use
    // /** 4th state triggered during a Right -> Left swipe. */
    // MCSwipeTableViewCellStateLeft4 = (1 << 7),
    // MCSwipeTableViewCellStateFromRight4 = (1 << 7),

    /************************/
    /** Legacy option names */

    /** 1st state triggered during a Left -> Right swipe. */
    MCSwipeTableViewCellState1 = (1 << 0),
    
    /** 2nd state triggered during a Left -> Right swipe. */
    MCSwipeTableViewCellState2 = (1 << 1),

    /** 1st state triggered during a Right -> Left swipe. */
    MCSwipeTableViewCellState3 = (1 << 2),
    
    /** 2nd state triggered during a Right -> Left swipe. */
    MCSwipeTableViewCellState4 = (1 << 3)
};

/** Describes the mode used during a swipe */
typedef NS_ENUM(NSUInteger, MCSwipeTableViewCellMode) {
    /** Disabled swipe.  */
    MCSwipeTableViewCellModeNone = 0,

    /** Upon swipe the cell if exited from the view. Useful for destructive actions. */
    MCSwipeTableViewCellModeExit,

    /** Upon swipe the cell if automatically swiped back to it's initial position. */
    MCSwipeTableViewCellModeSwitch
};

/**
 *  `MCSwipeCompletionBlock`
 *
 *  @param cell  Currently swiped `MCSwipeTableViewCell`.
 *  @param state `MCSwipeTableViewCellState` which has been triggered.
 *  @param mode  `MCSwipeTableViewCellMode` used for for swiping.
 *
 *  @return No return value.
 */
typedef void (^MCSwipeCompletionBlock)(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode);

@protocol MCSwipeTableViewCellDelegate;

@interface MCSwipeTableViewCell : UITableViewCell

/** Delegate of `MCSwipeTableViewCell` */
@property (nonatomic, assign) id <MCSwipeTableViewCellDelegate> delegate;

/** 
 * Damping of the physical spring animation. Expressed in percent.
 * 
 * @discussion Only applied for version of iOS > 7.
 */
@property (nonatomic, assign, readwrite) CGFloat damping;

/**
 * Velocity of the spring animation. Expressed in points per second (pts/s).
 *
 * @discussion Only applied for version of iOS > 7.
 */
@property (nonatomic, assign, readwrite) CGFloat velocity;

/** Duration of the animations. */
@property (nonatomic, assign, readwrite) NSTimeInterval animationDuration;


/** Color for background, when no state has been triggered. */
@property (nonatomic, strong, readwrite) UIColor *defaultColor;


/** 1st color of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorR1;

/** 2nd color of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorR2;

/** 3rd color of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorR3;

/** 1st color of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorL1;

/** 2nd color of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorL2;

/** 3rd color of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIColor *colorL3;


/** 1st view of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIView *viewR1;

/** 2nd view of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIView *viewR2;

/** 3rd view of the state triggered during a Left -> Right swipe. */
@property (nonatomic, strong, readwrite) UIView *viewR3;

/** 1st view of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIView *viewL1;

/** 2nd view of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIView *viewL2;

/** 3rd view of the state triggered during a Right -> Left swipe. */
@property (nonatomic, strong, readwrite) UIView *viewL3;


/** 1st Block of the state triggered during a Left -> Right swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockR1;

/** 2nd Block of the state triggered during a Left -> Right swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockR2;

/** 3rd Block of the state triggered during a Left -> Right swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockR3;

/** 1st Block of the state triggered during a Right -> Left swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockL1;

/** 2nd Block of the state triggered during a Right -> Left swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockL2;

/** 3rd Block of the state triggered during a Right -> Left swipe. */
@property (nonatomic, copy, readwrite) MCSwipeCompletionBlock completionBlockL3;


// Percentage of when the first and second action are activated, respectively

/** Percentage value to trigger the 1st state of a swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat firstTrigger;

/** Percentage value to trigger the 2nd state of a swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat secondTrigger;

/** Percentage value to trigger the 1st state of a right swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat rightFirstTrigger;

/** Percentage value to trigger the 2nd state of a right swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat rightSecondTrigger;

/** Percentage value to trigger the 3rd state of a right swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat rightThirdTrigger;

/** Percentage value to trigger the 1st state of a left swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat leftFirstTrigger;

/** Percentage value to trigger the 2nd state of a left swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat leftSecondTrigger;

/** Percentage value to trigger the 3rd state of a left swipe gesture. */
@property (nonatomic, assign, readwrite) CGFloat leftThirdTrigger;

@property (nonatomic) NSArray<NSNumber *> *rightTriggers;
@property (nonatomic) NSArray<NSNumber *> *leftTriggers;


/** 1st `MCSwipeTableViewCellMode` of the state triggered during a Left -> Right swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateR1;

/** 2nd `MCSwipeTableViewCellMode` of the state triggered during a Left -> Right swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateR2;

/** 3rd `MCSwipeTableViewCellMode` of the state triggered during a Left -> Right swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateR3;

/** 1st `MCSwipeTableViewCellMode` of the state triggered during a Right -> Left swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateL1;

/** 2nd `MCSwipeTableViewCellMode` of the state triggered during a Right -> Left swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateL2;

/** 3rd `MCSwipeTableViewCellMode` of the state triggered during a Right -> Left swipe. */
@property (nonatomic, assign, readwrite) MCSwipeTableViewCellMode modeForStateL3;


/** Boolean indicator to know if the cell is currently dragged. */
@property (nonatomic, assign, readonly, getter=isDragging) BOOL dragging;

/** Boolean to enable/disable the dragging ability of a cell. */
@property (nonatomic, assign, readwrite) BOOL shouldDrag;

/** Boolean to enable/disable the animation of the view during the swipe.  */
@property (nonatomic, assign, readwrite) BOOL shouldAnimateIcons;

/**
 *  Configures the properties of a cell.
 *
 *  @param view            view of the state triggered during a swipe.
 *  @param color           Color of the state triggered during a swipe.
 *  @param mode            `MCSwipeTableViewCellMode` used by the cell during a swipe.
 *  @param state           `MCSwipeTableViewCellState` on which the properties are applied.
 *  @param completionBlock Block of the state triggered during a swipe.
 */
- (void)setSwipeGestureWithView:(UIView *)view
                          color:(UIColor *)color
                           mode:(MCSwipeTableViewCellMode)mode
                          state:(MCSwipeTableViewCellState)state
                completionBlock:(MCSwipeCompletionBlock)completionBlock;


/**
 *  Swiped back the cell to it's original position
 *
 *  @param completion Callback block executed at the end of the animation.
 */
- (void)swipeToOriginWithCompletion:(void(^)(void))completion;

@end


@protocol MCSwipeTableViewCellDelegate <NSObject>

@optional

/**
 *  Called when the user starts swiping the cell.
 *
 *  @param cell `MCSwipeTableViewCell` currently swiped.
 */
- (void)swipeTableViewCellDidStartSwiping:(MCSwipeTableViewCell *)cell;

/**
 *  Called when the user ends swiping the cell.
 *
 *  @param cell `MCSwipeTableViewCell` currently swiped.
 */
- (void)swipeTableViewCellDidEndSwiping:(MCSwipeTableViewCell *)cell;

/**
 *  Called during a swipe.
 *
 *  @param cell         Cell that is currently swiped.
 *  @param percentage   Current percentage of the swipe movement. Percentage is calculated from the
 *                      left of the table view.
 */
- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didSwipeWithPercentage:(CGFloat)percentage;

@end
