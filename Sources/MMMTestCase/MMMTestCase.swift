//
// MMMTestCase. Part of MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

import Foundation
import MMMCommonCore
import SwiftUI
import UIKit

#if SWIFT_PACKAGE
import MMMTestCaseObjC

@_exported import MMMTestCaseObjC
#endif

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
}

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

	public func verify(viewController: UIViewController, fit: MMMTestCaseSize = .screenWidthTableHeight, identifier: String = "", backgroundColor: UIColor? = nil) {

		if !viewController.isViewLoaded {

			// To ensure viewWillAppear and friends are properly called.
			viewController.beginAppearanceTransition(true, animated: false)
			viewController.endAppearanceTransition()

			// Modal view controllers are often meant to be laid out via frame-based way,
			// while we want to use Auto Layout here.
			viewController.view.translatesAutoresizingMaskIntoConstraints = false
		}

		self.__verifyView(
			viewController.view,
			fitSizes: [ fit.asValue() ],
			identifier: identifier,
			backgroundColor: backgroundColor
		)
	}

	private func sizeForFit(_ fit: MMMTestCaseSize) -> CGSize {
		switch fit {
		case .natural: return self.fitSize(forPresetFit: .natural)
		case .screenWidth: return self.fitSize(forPresetFit: .screenWidth)
		case .screenWidthTableHeight: return self.fitSize(forPresetFit: .screenWidthTableHeight)
		case let .size(width, height): return .init(width: width, height: height)
		}
	}

	@available(iOS 16, *)
	public func testableView<T: SwiftUI.View>(
		from view: T,
		fit: MMMTestCaseSize = .screenWidthTableHeight
	) -> UIView {

		let controller = UIHostingController(rootView: view)
		controller.sizingOptions = .intrinsicContentSize
		if #available(iOS 16.4, tvOS 16.4, *) {
			controller.safeAreaRegions = []
		}
		controller.view.translatesAutoresizingMaskIntoConstraints = false

		let fitSize = sizeForFit(fit)

		switch fit {
		case .natural:
			controller.view.setContentCompressionResistancePriority(.required, for: .horizontal)
			controller.view.setContentCompressionResistancePriority(.required, for: .vertical)
			controller.view.widthAnchor.constraint(
				lessThanOrEqualToConstant: sizeForFit(.screenWidth).width
			).isActive = true
		case .screenWidth:
			controller.view.widthAnchor.constraint(equalToConstant: fitSize.width).isActive = true
			controller.view.setContentCompressionResistancePriority(.required, for: .vertical)
		case .screenWidthTableHeight:
			controller.view.widthAnchor.constraint(equalToConstant: fitSize.width).isActive = true
			controller.view.heightAnchor.constraint(equalToConstant: fitSize.height).isActive = true
		case .size(let width, let height):
			controller.view.widthAnchor.constraint(equalToConstant: width).isActive = true
			controller.view.heightAnchor.constraint(equalToConstant: height).isActive = true
		}

		controller.view.setNeedsLayout()

		controller.view.drawHierarchy(in: .init(
			origin: .zero,
			size: controller.view.systemLayoutSizeFitting(.zero)
		), afterScreenUpdates: true)

		// We need the layout to happen naturally now.
		pumpRunLoopABit()

		return controller.view
	}

	@available(iOS 16, *)
	public func verify<T: SwiftUI.View>(
		view: T,
		fit: MMMTestCaseSize = .screenWidthTableHeight,
		identifier: String = "",
		backgroundColor: UIColor? = nil
	) {

		let fitSize = sizeForFit(fit)

		verify(
			view: testableView(from: view, fit: fit),
			fit: fit,
			identifier: [
				identifier,
				fitSize.width > 0 ? String(format: "w%.f", fitSize.width) : nil,
				fitSize.height > 0 ? String(format: "h%.f", fitSize.height) : nil
			].compactMap { $0 }.joined(separator: "_"),
			backgroundColor: backgroundColor
		)
	}

	@available(iOS 16, *)
	public func verify(previews: SwiftUI._PreviewProvider.Type, fit: MMMTestCaseSize) {
		for preview in previews._allPreviews {
			let view = preview.content

			if let identifier = identifierFromPreview(preview) {
				self.verify(view: view, fit: fit, identifier: identifier)
			} else {
				NSLog("No displayName provided, skipped preview snapshot")
			}
		}
	}

	private func identifierFromPreview(_ preview: _Preview) -> String? {
		preview.displayName.map {
			$0.split(separator: " ").map(\.capitalized).joined(separator: "")
		}
	}

	/// Helps generating parameter dictionaries suitable for `varyParameters` from enums supporting `CaseIterable`.
	public func allTestCases<T: CaseIterable>(_ type: T.Type) -> [String: T] {
		.init(uniqueKeysWithValues:
				T.allCases
			.map { (String(MMMTypeName($0).split(separator: ".").last!), $0) }
			.sorted { a, b in a.0 < b.0 }
		)
	}
}
