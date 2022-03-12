//
// MMMTestCase. Part of MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

#import "MMMTestCase.h"

/**
 * Protocol for a set of values of a certain test parameter.
 */
@protocol MMMTestCaseParameter <NSObject>

/** The name identifying this parameter. */
@property (nonatomic, readonly) NSString *name;

/** The total number of possible values the parameter might have, the size of the set of values.
 * This should never change during the lifetime of the parameter. */
@property (nonatomic, readonly) NSInteger size;

/** 
 * A particular element from the set of values this parameter can have.
 * It's not a simple array because values can be generated, for example.
 */
- (id)valueForIndex:(NSInteger)index;

/** 
 * An identifier to use for the value of the parameter with the given index, such as 'longTitle' or 'shortTitle'.
 * The identifier can be further used in the file name of the corresponding test output, etc. 
 */
- (NSString *)identifierForValueWithIndex:(NSInteger)index;

@end

/**
 * A test parameter that can have values from the set of fixed values.
 */
@interface MMMTestCaseParameter : NSObject <MMMTestCaseParameter>

/**
 * @param name  The name of the parameter.
 *
 * @param values  Possible values for this parameter as (key, value) pairs, i.e. each value should have its own identifier
 * such as 'longTitle', 'shortTitile'.
 */
- (id)initWithName:(NSString *)name values:(NSDictionary<NSString *, id> *)values NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;

@end

/** A particular value of a varying parameter with an identifier attached */
@interface MMMTestCaseParameterValue : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) id value;

- (id)initWithIdentifier:(NSString *)identifier value:(id)value NS_DESIGNATED_INITIALIZER;
- (id)init NS_UNAVAILABLE;

@end

@implementation MMMTestCaseParameterValue

- (id)initWithIdentifier:(NSString *)identifier value:(id)value {
	if (self = [super init]) {
		_identifier = identifier;
		_value = value;
	}
	return self;
}

@end

//
//
//
@implementation MMMTestCaseParameter {
	// We need to store values ordered somehow, so we can retrieve them by index.
	NSMutableArray<MMMTestCaseParameterValue *> *_values;
}

@synthesize name=_name;

- (id)initWithName:(NSString *)name values:(NSDictionary<NSString *, id> *)values {

	if (self = [super init]) {

		_name = [name copy];

		_values = [[NSMutableArray alloc] initWithCapacity:[values count]];
		for (NSString *name in [values keyEnumerator]) {
			[_values addObject:[[MMMTestCaseParameterValue alloc]
				initWithIdentifier:name
				value:[values objectForKey:name]
			]];
		}

		// Sorting the values by name to always have definite order.
		[_values sortUsingComparator:^NSComparisonResult(MMMTestCaseParameterValue *obj1, MMMTestCaseParameterValue *obj2) {
			return [obj1.identifier compare:obj2.identifier];
		}];
	}

	return self;
}

- (NSInteger)size {
	return [_values count];
}

- (id)valueForIndex:(NSInteger)index {
	return _values[index].value;
}

- (NSString *)identifierForValueWithIndex:(NSInteger)index {
	return _values[index].identifier;
}

@end

/**
 */
@interface MMMTestCaseContainer : UIView

@property (nonatomic, readwrite) CGRect testViewAlignmentRect;

- (id)init NS_DESIGNATED_INITIALIZER;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

@implementation MMMTestCaseContainer {
	UIView *_autoLayoutContainer;
	UIView *_childView;
	CGSize _childViewSize;
}

- (id)init {

	if (self = [super initWithFrame:CGRectZero]) {

		_autoLayoutContainer = [[UIView alloc] init];
		_autoLayoutContainer.opaque = NO;
		_autoLayoutContainer.backgroundColor = [UIColor clearColor];
		_autoLayoutContainer.translatesAutoresizingMaskIntoConstraints = YES;

		[self addSubview:_autoLayoutContainer];
	}

	return self;
}

- (void)setChildView:(UIView *)childView size:(CGSize)size {

	NSAssert(_childView == nil, @"");

	_childViewSize = size;
	_childView = childView;

	_autoLayoutContainer.frame = CGRectMake(0, 0, _childViewSize.width, _childViewSize.height);
	[_autoLayoutContainer addSubview:_childView];

	if (_childView.translatesAutoresizingMaskIntoConstraints) {
	} else {
		NSDictionary *views = NSDictionaryOfVariableBindings(_childView);
		[_autoLayoutContainer addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"H:|[_childView]|"
			options:0 metrics:nil views:views
		]];
		[_autoLayoutContainer addConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"V:|[_childView]|"
			options:0 metrics:nil views:views
		]];
	}

	[_autoLayoutContainer layoutIfNeeded];
}

- (UIEdgeInsets)safetyBorderInsets {
	return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (CGRect)safetyBounds {
	return UIEdgeInsetsInsetRect(self.bounds, [self safetyBorderInsets]);
}

- (UIColor *)safetyAreaColor {
	return [UIColor colorWithWhite:0.9 alpha:1];
}

- (UIColor *)safetyBorderColor {
	return [UIColor colorWithWhite:.45 alpha:1];
}

- (UIColor *)alignmentRectColor {
	// The color that is rarely used for background and that people have got used to in Photoshop and other tools.
	return [[UIColor cyanColor] colorWithAlphaComponent:0.5];
}

- (CGSize)sizeThatFits:(CGSize)size {
	UIEdgeInsets insets = [self safetyBorderInsets];
	return CGSizeMake(
		insets.left + _childViewSize.width + insets.right,
		insets.top + _childViewSize.height + insets.bottom
	);
}

- (void)layoutSubviews {
	_autoLayoutContainer.frame = [_childView alignmentRectForFrame:[self safetyBounds]];
	_childView.frame = [_childView frameForAlignmentRect:_autoLayoutContainer.bounds];
	[self setNeedsDisplay];
}

//
// These are copied from MMMTemple because we don't want MMMTestCase depend on it.
//

static inline CGFloat _MMMPixelRound(CGFloat pointValue) {
	const CGFloat scale = [UIScreen mainScreen].scale;
	return roundf(pointValue * scale) / scale;
}

static CGFloat _MMMPhaseForDashedPattern(CGFloat lineLength, CGFloat dashLength, CGFloat skipLength) {

	// We want to tweak the phase so the start of the line looks (almost) the same as its end.
	// The idea here is that in order for the line to be cut symmetrically either the center of the dash or the center
	// of the skip part of the pattern should reside in the center of the line. We calculate two phases assuming either
	// dashed or skipped part in the center and then picking the one leading to the cut on the dashed part of the pattern.
	// Note that we don't want to cut in the middle of a pixel, that's why we have "pixel" rounds below.
	CGFloat patternWidth = dashLength + skipLength;

	// Half of the line length before the dashed part in the center.
	// | ----  ----  ... ----  --|--  ----  ...
	// [          dw                  ]
	CGFloat dw = (lineLength - dashLength) / 2 + patternWidth;
	CGFloat phaseDash = -_MMMPixelRound(dw - floor(dw / patternWidth) * patternWidth);

	// Half of the line length with the skipped part in the center.
	// |--  ----  ----  ... ---- | ----  ...
	// [          sw                     ]
	CGFloat sw = (lineLength + skipLength) / 2 + patternWidth;
	CGFloat phaseSkip = -_MMMPixelRound(sw - floor(sw / patternWidth) * patternWidth);

	if (phaseDash >= -skipLength && phaseSkip >= -skipLength) {
		// Let's try to make the skip smaller at least.
		return MAX(phaseDash, phaseSkip);
	} else {
		// Maximizing the dashed part.
		return MIN(phaseDash, phaseSkip);
	}
}

//
//
//

- (void)drawRect:(CGRect)rect {

	CGRect b = self.bounds;

	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSaveGState(c);

	CGFloat halfLineWidth = .5;

	//
	// Safety area backtround.
	//
	[[self safetyAreaColor] setFill];
	CGContextFillRect(c, b);

	//
	// The actual background.
	//
	[self.backgroundColor setFill];
	CGContextFillRect(c, [self safetyBounds]);

	//
	// Guidlines corresponding to the alignment rectangle.
	//
	{
		CGRect r = [_childView alignmentRectForFrame:[self safetyBounds]];

		CGContextMoveToPoint(c, CGRectGetMinX(r) - halfLineWidth, CGRectGetMinY(b));
		CGContextAddLineToPoint(c, CGRectGetMinX(r) - halfLineWidth, CGRectGetMaxY(b));

		CGContextMoveToPoint(c, CGRectGetMaxX(r) + halfLineWidth, CGRectGetMinY(b));
		CGContextAddLineToPoint(c, CGRectGetMaxX(r) + halfLineWidth, CGRectGetMaxY(b));

		CGContextMoveToPoint(c, CGRectGetMinX(b), CGRectGetMinY(r) - halfLineWidth);
		CGContextAddLineToPoint(c, CGRectGetMaxX(b), CGRectGetMinY(r) - halfLineWidth);

		CGContextMoveToPoint(c, CGRectGetMinX(b), CGRectGetMaxY(r) + halfLineWidth);
		CGContextAddLineToPoint(c, CGRectGetMaxX(b), CGRectGetMaxY(r) + halfLineWidth);

		CGContextSetLineWidth(c, 2 * halfLineWidth);
		[[self alignmentRectColor] setStroke];
		CGContextStrokePath(c);
	}

	//
	// Safety area border.
	//
	{
		CGContextSaveGState(c);

		[[self safetyBorderColor] setStroke];

		CGRect safetyBorderRect = UIEdgeInsetsInsetRect(
			[self safetyBounds],
			UIEdgeInsetsMake(-halfLineWidth, -halfLineWidth, -halfLineWidth, -halfLineWidth)
		);

		const CGFloat dashLength = 2;
		const CGFloat skipLength = 5;
		const CGFloat pattern[] = { dashLength, skipLength };

		CGContextSetLineCap(c, kCGLineCapSquare);
		CGContextSetLineWidth(c, 2 * halfLineWidth);

		CGContextMoveToPoint(c, CGRectGetMinX(safetyBorderRect), CGRectGetMinY(safetyBorderRect));
		CGContextAddLineToPoint(c, CGRectGetMaxX(safetyBorderRect), CGRectGetMinY(safetyBorderRect));
		CGContextSetLineDash(c, _MMMPhaseForDashedPattern(CGRectGetWidth(safetyBorderRect), dashLength, skipLength), pattern, 2);
		CGContextStrokePath(c);

		CGContextMoveToPoint(c, CGRectGetMaxX(safetyBorderRect), CGRectGetMinY(safetyBorderRect));
		CGContextAddLineToPoint(c, CGRectGetMaxX(safetyBorderRect), CGRectGetMaxY(safetyBorderRect));
		CGContextSetLineDash(c, _MMMPhaseForDashedPattern(CGRectGetHeight(safetyBorderRect), dashLength, skipLength), pattern, 2);
		CGContextStrokePath(c);

		CGContextMoveToPoint(c, CGRectGetMinX(safetyBorderRect), CGRectGetMaxY(safetyBorderRect));
		CGContextAddLineToPoint(c, CGRectGetMaxX(safetyBorderRect), CGRectGetMaxY(safetyBorderRect));
		CGContextSetLineDash(c, _MMMPhaseForDashedPattern(CGRectGetWidth(safetyBorderRect), dashLength, skipLength), pattern, 2);
		CGContextStrokePath(c);

		CGContextMoveToPoint(c, CGRectGetMinX(safetyBorderRect), CGRectGetMinY(safetyBorderRect));
		CGContextAddLineToPoint(c, CGRectGetMinX(safetyBorderRect), CGRectGetMaxY(safetyBorderRect));
		CGContextSetLineDash(c, _MMMPhaseForDashedPattern(CGRectGetHeight(safetyBorderRect), dashLength, skipLength), pattern, 2);
		CGContextStrokePath(c);

		CGContextRestoreGState(c);
	}

	CGContextRestoreGState(c);
}

@end

//
//
//
@implementation MMMTestCase {
	// A cached value for the corresponding method, see below.
	NSOrderedSet *_referenceFolderSuffixes;
}

+ (BOOL)overrideRecordMode {

	static dispatch_once_t onceToken;
	static BOOL overrideViaEnvironment;
	dispatch_once(&onceToken, ^{
		NSString *value = [[NSProcessInfo processInfo].environment objectForKey:@"MMM_RECORD_MODE"];
		overrideViaEnvironment = (value && [value boolValue]);
	});
	if (overrideViaEnvironment)
		return YES;

	return NO;
}

- (BOOL)recordMode {
	return [self.class overrideRecordMode] ? YES : [super recordMode];
}

- (void)setRecordMode:(BOOL)recordMode {
	[super setRecordMode: [self.class overrideRecordMode] ? YES : recordMode];
}

- (void)setUp {

	[super setUp];

	if ([self.class overrideRecordMode]) {
		self.recordMode = YES;
	}
}

- (CGSize)fitSizeForPresetFit:(MMMTestCaseFit)fit {

	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	if (screenSize.width > screenSize.height) {
		CGFloat t = screenSize.width;
		screenSize.width = screenSize.height;
		screenSize.height = t;
	}

	switch (fit) {

		case MMMTestCaseFitNatural:
			return CGSizeMake(0, 0);

		case MMMTestCaseFitScreenWidth:
			return CGSizeMake(screenSize.width, 0);

		case MMMTestCaseFitScreenWidthTableHeight:
			return CGSizeMake(screenSize.width, screenSize.height - 20 - 44);

	}
}

- (void)verifyView:(UIView *)view fitSizes:(NSArray *)fitSizes identifier:(NSString *)identifier {
	[self verifyView:view fitSizes:fitSizes identifier:identifier backgroundColor:nil];
}

- (void)verifyView:(UIView *)view fitSizes:(NSArray *)fitSizes identifier:(NSString *)identifier backgroundColor:(UIColor *)backgroundColor {

	for (id fit in fitSizes) {

		CGSize fitSize;
		if ([fit isKindOfClass:[NSNumber class]]) {

			MMMTestCaseFit f = [fit integerValue];

			fitSize = [self fitSizeForPresetFit:f];

		} else if ([fit isKindOfClass:[NSValue class]]) {

			fitSize = [fit CGSizeValue];

		} else {
			NSAssert(NO, @"Unsupported class of the fit preset: %@", [fit class]);
			fitSize = CGSizeZero;
		}

		[self verifyView:view fitSize:fitSize identifier:identifier backgroundColor:backgroundColor];
	}
}

- (void)verifyView:(UIView *)view fitSize:(CGSize)fitSize identifier:(NSString *)identifier {
	[self verifyView:view fitSize:fitSize identifier:identifier backgroundColor:nil];
}

/** 
 * An ordered set of suffixes for the image reference folder eventually passed into FBSnapshotVerifyViewWithOptions().
 * Facebook's library uses "_32" and "_64" by default, while we are typically testing views for different screen widths 
 * and different devices (since the styles of labels/icons/etc can depend on the actual screen the app is running on, 
 * not just the width of a view).
 */
- (NSOrderedSet *)referenceFolderSuffixes {

	if (!_referenceFolderSuffixes) {

		NSMutableOrderedSet *result = [[NSMutableOrderedSet alloc] initWithArray:@[
			@"5", @"6", @"6Plus", @"Pad"
		]];

		CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

		NSString *firstSuffix = nil;
		if (screenWidth <= 320) {
			firstSuffix = @"5";
		} else if (screenWidth <= 375) {
			firstSuffix = @"6";
		} else if (screenWidth <= 414) {
			firstSuffix = @"6Plus";
		} else {
			firstSuffix = @"Pad";
		}

		if (firstSuffix) {
			[result removeObject:firstSuffix];
			[result insertObject:firstSuffix atIndex:0];
		}

		_referenceFolderSuffixes = result;
	}

	return _referenceFolderSuffixes;
}

/** 
 * A modified version of FBSnapshotVerifyViewWithOptions. 
 */
- (void)verifyView:(UIView *)view identifier:(NSString *)identifier suffixes:(NSOrderedSet *)suffixes tolerance:(CGFloat)tolerance {

	NSString *referenceImagesDirectory = [NSProcessInfo processInfo].environment[@"FB_REFERENCE_IMAGE_DIR"];
	if (!referenceImagesDirectory) {
		NSAssert(NO, @"Set FB_REFERENCE_IMAGE_DIR as environment variable in your scheme.");
		return;
	}

	if (self.recordMode) {

		NSError *error = nil;
		NSString *dir = [referenceImagesDirectory stringByAppendingString:[suffixes firstObject]];
		BOOL referenceImageSaved = [self compareSnapshotOfView:view referenceImagesDirectory:dir identifier:identifier tolerance:tolerance error:&error];
		if (!referenceImageSaved) {
			XCTFail(@"Could not save a reference image: %@", error);
		} else {
			XCTFail(@"Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!");
		}

	} else {

		for (NSString *suffix in suffixes) {

			NSError *error = nil;
			NSString *dir = [referenceImagesDirectory stringByAppendingString:suffix];
			if (![self referenceImageRecordedInDirectory:dir identifier:identifier error:&error]) {
				continue;
			}

			BOOL comparisonSuccess = [self compareSnapshotOfView:view referenceImagesDirectory:dir identifier:identifier tolerance:tolerance error:&error];
			XCTAssertTrue(comparisonSuccess, @"Snapshot comparison failed: %@", error);
			return;
		}

		XCTFail(@"Could not find any snapshots");
	}
}

- (void)pumpRunLoopABit {
	// We have to use a total timeout here in case we have a non-stop stream of events.
	// Note that it's different than passing a timeout to CFRunLoopRunInMode():
	// we want to pump "all events ready now unless there are too many that we don't have time left",
	// and not "all events that might show up during the timeframe we have".
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) == kCFRunLoopRunHandledSource) {
		if ([NSDate timeIntervalSinceReferenceDate] - startTime > 0.5) {
			NSLog(@"MMMTestCase: unable to pump all immediately pending events, the snapshot might be incorrect");
			break;
		}
	}
}

- (void)verifyView:(UIView *)view fitSize:(CGSize)fitSize identifier:(NSString *)identifier backgroundColor:(UIColor *)backgroundColor {

	if ([view isKindOfClass:[UITableViewCell class]]) {
		XCTFail(@"`UITableViewCell` should be wrapped into %@ for correct snapshots", [MMMTestCaseTableViewCellWrapper class]);
	}

	// An outermost container to make a snapshot of parts of the view sticking out of the alignment rectangle.
	MMMTestCaseContainer *outerContainer = [[MMMTestCaseContainer alloc] init];
	outerContainer.backgroundColor = backgroundColor ?: [UIColor whiteColor];

	// To ensure any small updates scheduled on the current run loop (or dispatch queue attached to it) are procesed before we begin measuring things.
	[self pumpRunLoopABit];

	CGSize size;

	if (view.translatesAutoresizingMaskIntoConstraints) {

		size = [view sizeThatFits:CGSizeMake(
			fitSize.width <= 0 ? 0 : fitSize.width,
			fitSize.height <= 0 ? 0 : fitSize.height
		)];

	} else {

		[view updateConstraintsIfNeeded];

		size = [view
			systemLayoutSizeFittingSize:CGSizeMake(
				fitSize.width <= 0 ? 0 : fitSize.width,
				fitSize.height <= 0 ? 0 : fitSize.height
			)
			withHorizontalFittingPriority:(fitSize.width <= 0) ? UILayoutPriorityFittingSizeLevel : UILayoutPriorityRequired
			verticalFittingPriority:(fitSize.height <= 0) ? UILayoutPriorityFittingSizeLevel : UILayoutPriorityRequired
		];
	}

	// Let's remember the superview this view was a part of, to restore this afterwards.
	UIView *originalSuperview = view.superview;
	NSInteger originalIndex = originalSuperview ? [view.superview.subviews indexOfObjectIdenticalTo:view] : NSNotFound;

	[outerContainer setChildView:view size:size];
	CGSize containerSize = [outerContainer sizeThatFits:CGSizeZero];
	outerContainer.frame = CGRectMake(0, 0, containerSize.width, containerSize.height);

	// A bit weird sequence, I know, but this is to avoid pesky Auto Layout warnings: the first call ensures the
	// container view has proper size before Auto Layout kicks in for its children.
	[outerContainer layoutSubviews];
	[outerContainer layoutIfNeeded];

	// Again, to make sure that all the performSelector and similar things scheduled just before the call
	// of verifyView() or due to a resize we've just made are going to be processed before we take the snapshot.
	// `UITableViewCell` won't handle selection properly (even non-animated ones) under iOS 13 without this.
	[self pumpRunLoopABit];

	NSMutableArray *identifierParts = [[NSMutableArray alloc] init];
	[identifierParts addObject:identifier];
	if (fitSize.width > 0)
		[identifierParts addObject:[NSString stringWithFormat:@"w%.f", fitSize.width]];
	if (fitSize.height > 0)
		[identifierParts addObject:[NSString stringWithFormat:@"h%.f", fitSize.height]];

	NSString *combinedIdentifier = [identifierParts componentsJoinedByString:@"_"];

	// We allow 5% tolerance by default, so differences between iPhone 5 and 5s don't break the tests.
	[self verifyView:outerContainer identifier:combinedIdentifier suffixes:[self referenceFolderSuffixes] tolerance:0.05];

	// Let's restore the superview.
	if (originalSuperview) {
		[originalSuperview insertSubview:view atIndex:originalIndex];
	} else {
		[view removeFromSuperview];
	}
}

- (NSString *)stringForIndex:(NSInteger)index valueIdentifiers:(NSArray<NSString *> *)identifiers {
	return [[NSString stringWithFormat:@"%03ld__", (long)index] stringByAppendingString:[identifiers componentsJoinedByString:@"__"]];
}

- (void)varyParameters:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)parameters
	block:(void (^)(NSString *combinationIdentifier, NSDictionary<NSString *, id> *values))block
{
	// Make an array of parameters from name -> values pairs.
	NSMutableArray *parametersArray = [[NSMutableArray alloc] initWithCapacity:parameters.count];
	for (NSString *name in [parameters keyEnumerator]) {
		MMMTestCaseParameter *p = [[MMMTestCaseParameter alloc] initWithName:name values:parameters[name]];
		[parametersArray addObject:p];
	}

	// Let's have them sorted by name, so our combinations always have the same order.
	[parametersArray sortUsingComparator:^NSComparisonResult(MMMTestCaseParameter *p1, MMMTestCaseParameter *p2) {
		return [p1.name compare:p2.name];
	}];

	[self varyParametersArray:parametersArray block:block];
}

- (void)varyParametersArray:(NSArray<MMMTestCaseParameter *> *)parameters
	block:(void (^)(NSString *combinationIdentifier, NSDictionary<NSString *, id> *values))block
{
	NSInteger count = parameters.count;

	// Here we'll keep indexes of values we pick for every parmeter in the list.
	// We'll be incrementing this as a big counter with each digit running from 0 to the number of possible value
	// of the corresponding parameter (parameter (count - 1 - i) would correspond to digit i, this is so "most significant"
	// parameters change slower).
	// We'll have one extra digit after all of them to detect a carry-over which happens when we should stop counting.
	NSInteger *indexes = alloca(sizeof(NSInteger) * (count + 1));
	memset(indexes, 0, sizeof(NSInteger) * (count + 1));

	// Let's also assign an index to every combination, so we can preserve the order.
	NSInteger combinationIndex = 0;

	do {

		// Write out all the current values and their identifiers.
		NSMutableDictionary *values = [[NSMutableDictionary alloc] initWithCapacity:parameters.count];
		NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:parameters.count];
		for (NSInteger i = 0; i < count; i++) {

			NSInteger valueIndex = indexes[count - 1 - i];

			[identifiers addObject:[parameters[i] identifierForValueWithIndex:valueIndex]];
			[values
				setObject:[parameters[i] valueForIndex:valueIndex]
				forKey:parameters[i].name
			];
		}

		// And feed them to the block.
		block([self stringForIndex:combinationIndex valueIdentifiers:identifiers], values);

		// Now let's try to increment our big counter.
		indexes[0]++;
		for (NSInteger i = 0; i < count; i++) {

			// Done incrementing if have no carry over in this position.
			if (indexes[i] < parameters[count - 1 - i].size)
				break;

			// OK, carry over to the next position. Remember that we have an extra position, so it's always safe.
			indexes[i] = 0;
			indexes[i + 1]++;
		}

		// And the index of the whole combination as well.
		combinationIndex++;

	} while (indexes[count] == 0);
}

- (NSArray *)shuffledArrayFromArray:(NSArray *)array {

	NSMutableArray *result = [[NSMutableArray alloc] initWithArray:array];
	for (NSInteger i = 0; i < array.count; i++) {
		NSInteger pick = i + arc4random_uniform((uint32_t)(array.count - i));
		id temp = result[i];
		result[i] = result[pick];
		result[pick] = temp;
	}

	return result;
}

- (void)performInRandomOrder:(NSArray<RandomOrderBlock> *)blocks {
	for (RandomOrderBlock block in [self shuffledArrayFromArray:blocks]) {
		block();
	}
}

- (void)performInOrder:(NSArray<RandomOrderBlock> *)blocks {
	for (RandomOrderBlock block in blocks) {
		block();
	}
}

@end

//
//
//
@interface MMMTestCaseTableViewCellWrapper () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MMMTestCaseTableViewCellWrapper {
	UITableViewCell *_cell;
}

- (id)initWithTableViewCell:(UITableViewCell *)cell {

	if (self = [super initWithFrame:CGRectMake(0, 0, M_E, M_PI)]) {

		// Want this view to use old-school sizeThatFits: call.
		self.translatesAutoresizingMaskIntoConstraints = YES;

		_cell = cell;

		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, M_E, M_PI)];
		_tableView.translatesAutoresizingMaskIntoConstraints = YES;
		_tableView.rowHeight = UITableViewAutomaticDimension;
		_tableView.dataSource = self;
		_tableView.delegate = self;
		[self addSubview:_tableView];

		// Want to trigger a reload of our cell asap, so the prepareForReuse won't reset highlighted/selected state
		// possibly set just before calling verifyView().
		[self layoutIfNeeded];
	}

	return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return _cell;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return [_cell
		systemLayoutSizeFittingSize:size
		withHorizontalFittingPriority:size.width <= 0 ? UILayoutPriorityFittingSizeLevel : UILayoutPriorityRequired
		verticalFittingPriority:size.height <= 0 ? UILayoutPriorityFittingSizeLevel : UILayoutPriorityRequired
	];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	_tableView.frame = self.bounds;
}

- (void)reload {
	[_tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
	[self layoutIfNeeded];
	while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.2, false) == kCFRunLoopRunHandledSource)
		;
}

@end
