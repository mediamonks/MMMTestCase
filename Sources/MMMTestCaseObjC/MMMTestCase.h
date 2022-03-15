//
// MMMTestCase. Part of MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

#if SWIFT_PACKAGE
#import "FBSnapshotTestCase.h"
#else
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/** 
 * Presets for some common size constraints used with snapshot-based testing.
 * Please note that it's not a full list here, but some common values that might be useful.
 */
typedef NS_ENUM(NSInteger, MMMTestCaseFit) {

	/** The natural width and height of the view will be used. */
	MMMTestCaseFitNatural,

	/** The width of the current screen will be used, the height will be natural. */
	MMMTestCaseFitScreenWidth,

	/** The width of the current screen and the height of the screen without status and navigation bars. */
	MMMTestCaseFitScreenWidthTableHeight
};

@protocol MMMTestCaseVaryingParameter;

/** 
 * A base for our test cases, to be able to share some utility functions.
 */
@interface MMMTestCase : FBSnapshotTestCase

/** 
 * If this is YES, then `recordMode` property will be overriden to YES for all the descendants of MMMTestCase.
 *
 * This is handy when you need to re-record all the snapshot-based unit tests without tweaking `recordMode` property 
 * of each case.
 *
 * This is set to NO by default, i.e. each class defines `recordMode` for itself.
 *
 * To enable the override, set the environment variable "MMM_RECORD_MODE" to "1" or "YES" when running your tests
 * (or just jump into the implementation and return YES temporarily).
 */
+ (BOOL)overrideRecordMode;

/** 
 * Verifies the given view against the corresponding snapshot recorded earlier or records a snapshot, 
 * if recordMode property is YES.
 *
 * The view is laid out in an opaque container with the given background color and size before comparison or snapshot 
 * is made. (Zero components in `fitSize` will be treated as view's natural size for the corresponding dimension.)
 *
 * A 10px gray "safety" border is added around the container and 4 guidelines corresponding to the view's alignment
 * rectangle are drawn.
 */
- (void)verifyView:(UIView *)view fitSize:(CGSize)fitSize identifier:(NSString *)identifier backgroundColor:(nullable UIColor *)backgroundColor NS_REFINED_FOR_SWIFT;

/** A shortcut for the above method using white background. */
- (void)verifyView:(UIView *)view fitSize:(CGSize)fitSize identifier:(NSString *)identifier NS_SWIFT_UNAVAILABLE("");

/** A CGSize value suitable for `fitSize` parameter of `verifyView:fitSize:identifier:backgroundColor` corresponding 
* to the given fit preset. */
- (CGSize)fitSizeForPresetFit:(MMMTestCaseFit)fit;

/** 
 * Calls `verifyView:fitSize:identifier:backgroundColor:` for each of the sizes in the `fitSizes` array. Each element 
 * of this array is either an NSNumber-wrapped value of `MMMTestCaseFit` or a direct NSValue-wrapped CGSize values 
 * suitable for the above method.
 */
- (void)verifyView:(UIView *)view
	fitSizes:(NSArray<NSValue *> *)fitSizes
	identifier:(NSString *)identifier
	backgroundColor:(nullable UIColor *)backgroundColor NS_REFINED_FOR_SWIFT;

- (void)verifyView:(UIView *)view
	fitSizes:(NSArray<NSValue *> *)fitSizes
	identifier:(NSString *)identifier NS_SWIFT_UNAVAILABLE("");

- (void)verifyView:(UIView *)view
	identifier:(NSString *)identifier
	suffixes:(NSOrderedSet *)suffixes
	tolerance:(CGFloat)tolerance DEPRECATED_MSG_ATTRIBUTE("Does not seem to be used");

/** 
 * Runs the given block with all the possible combinations of the given parameters.
 * For example, we want to check all the combinations of title and location strings in one of the cells, so we call:
 * \code
 * 	[self
 * 		varyParameters:@{
 * 			@"title" : @{
 * 				@"small" : @"Suspendisse aliquet.",
 * 				@"large" : @"Mauris risus lacus, placerat quis tristique a, suscipit id velit.",
 * 				@"extreme" : @"Nunc pellentesque, nisl ut scelerisque rutrum, leo erat egestas turpis, nec molestie tellus leo id libero."
 * 			},
 * 			@"location" : @{
 * 				@"small" : @"Location.",
 * 				@"extreme" : @"Location taking much more characters to describe.",
 * 			}
 * 		}
 * 		block:^(NSString *combinationIdentifier, NSDictionary<NSString *,id> *values) {
 *
 * 			ViewModel *viewModel = [[ViewModel alloc]
 * 				initWithTitle:values[@"title"]
 * 				date:[NSDate dateWithTimeIntervalSince1970:0]
 * 				location:values[@"location"]
 * 			];
 *
 *			// ...
 * \endcode
 */
- (void)varyParameters:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)parameters
	block:(void (^)(NSString *combinationIdentifier, NSDictionary<NSString *, id> *values))block;

typedef void (^RandomOrderBlock)();

/**
 * The order in which properties of an object are accessed should not matter, however sometimes the code is not ready
 * for changes in certain "bad" order, so it might be a good idea to randomize it when unit testing something.
 *
 * For example:
 *
 * \code
 * [self performInRandomOrder:@[
 *     ^() { textField.placeholder = [values[@"placeholder"] mmm_stripNSNull]; },
 *     ^() { textField.secureTextEntry = [values[@"secure"] boolValue]; },
 *     ^() { textField.text = [values[@"text"] mmm_stripNSNull]; }
 * ]];
 * \endcode
 */
- (void)performInRandomOrder:(NSArray<RandomOrderBlock> *)blocks NS_SWIFT_NAME(performInRandomOrder(_:));

/** This is a quick inverse for `performInRandomOrder:` above.
 * Can be handy when you just want to quickly verify that it's the random order that is causing some problems. */
- (void)performInOrder:(NSArray<RandomOrderBlock> *)blocks;

- (NSOrderedSet *)referenceFolderSuffixes;

@end

/**
 * To wrap `UITableViewCell`s when snapshotting them.
 * Create it only once when you create a cell and use for every `verifyView()` call.
 *
 * This is needed because starting with iOS 13 or so it's not possible to use table view cells as standalone views
 * when testing: among other issues the children of `contentView` are not properly resized even after explicit
 * `layoutSubviews` calls on `contentView` or the cell itself.
 *
 * The idea is to host such a cell in a temporary table view and snapshot it while there.
 *
 * Note that I tried to create such a wrapper transparently for every invocation of `verifyView()`,
 * but this was causing issues with selected and highlighted states. So the user has to create it once and reuse
 * for all the invocations.
 */
NS_SWIFT_NAME(MMMTestCase.TableViewCellWrapper)
@interface MMMTestCaseTableViewCellWrapper<CellType: UITableViewCell *>: UIView

/** The cell being wrapped. */
@property (nonatomic, readonly) CellType cell;

/** The hosting table view in case you want to adjust background color. Don't overuse though. */
@property (nonatomic, readonly) UITableView *tableView;

- (void)reload;

- (id)initWithTableViewCell:(CellType)cell NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(_:));

- (id)init NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
