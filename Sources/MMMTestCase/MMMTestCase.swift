//
// MMMTestCase. Part of MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

import Foundation

/// Possible sizes of a test container view used with verify(view:*) methods of MMMTestCase.
public enum MMMTestCaseSize {

	/// Use the natural size of the view being tested.
	///
	/// "Natural" is the size the view would occupy without being constrained (well, technically constrained
	/// to be of zero size with very low priorities).
	case natural

	/// Use the width of the current screen and the natural height of the view being tested.
	case screenWidth

	/// Use the width of the current screen and the height of it without status and navigation bars.
	case screenWidthTableHeight

	/// Use a concrete size of the container.
	///
	/// Note that zeros will be treated as "natural" size in the corresponding dimension.
	case size(width: CGFloat, height: CGFloat)

	fileprivate func asValue() -> NSValue {
		switch self {
			case .natural:
				return NSNumber(value: MMMTestCaseFit.natural.rawValue)
			case .screenWidth:
				return NSNumber(value: MMMTestCaseFit.screenWidth.rawValue)
			case .screenWidthTableHeight:
				return NSNumber(value: MMMTestCaseFit.screenWidthTableHeight.rawValue)
			case let .size(width, height):
				return NSValue(cgSize: CGSize(width: width, height: height))
		}
	}
};

extension MMMTestCase {

	public func verify(view: UIView, fits: [MMMTestCaseSize], identifier: String = "", backgroundColor: UIColor? = nil) {
		self.__verifyView(
			view,
			fitSizes: fits.map { $0.asValue() },
			identifier: identifier,
			backgroundColor: backgroundColor
		)
	}

	public func verify(view: UIView, fit: MMMTestCaseSize, identifier: String = "", backgroundColor: UIColor? = nil) {
		self.__verifyView(
			view,
			fitSizes: [ fit.asValue() ],
			identifier: identifier,
			backgroundColor: backgroundColor
		)
	}
}
