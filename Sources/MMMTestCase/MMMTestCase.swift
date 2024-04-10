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

	private class WrapperController: UIViewController {

		private let viewController: UIViewController

		public init(_ viewController: UIViewController) {
			self.viewController = viewController
			super.init(nibName: nil, bundle: nil)
			addChild(viewController)
			viewController.didMove(toParent: self)
		}
		
		public required init?(coder: NSCoder) { fatalError() }

		public var fitSize: CGSize = .init(width: 320, height: 480)

		public private(set) lazy var container = MMMTestCaseContainer()

		override func viewDidLoad() {
			super.viewDidLoad()
			view.addSubview(container)
		}

		override func viewWillLayoutSubviews() {
			super.viewWillLayoutSubviews()
			container.setChildView(viewController.view, size: fitSize)
			let bounds = view.bounds.inset(by: view.safeAreaInsets)
			container.frame = .init(origin: bounds.origin, size: container.sizeThatFits(.zero))
		}
	}

	private func sizeForFit(_ fit: MMMTestCaseSize) -> CGSize {
		switch fit {
		case .natural: return self.fitSize(forPresetFit: .natural)
		case .screenWidth: return self.fitSize(forPresetFit: .screenWidth)
		case .screenWidthTableHeight: return self.fitSize(forPresetFit: .screenWidthTableHeight)
		case let .size(width, height): return .init(width: width, height: height)
		}
	}

	public func verify<T: SwiftUI.View>(view: T, fit: MMMTestCaseSize = .screenWidthTableHeight, identifier: String = "", backgroundColor: UIColor? = nil) {

		let window = UIWindow()
		let viewController = UIHostingController(rootView: view)
		let wrapper = WrapperController(viewController)

		window.rootViewController = wrapper
		window.windowLevel = .normal - 1 // It could be fun to watch snapshots, but let's keep older behavior.
		window.isHidden = false

		let fitSize = sizeForFit(fit)
		wrapper.fitSize = viewController.sizeThatFits(in: fitSize)
		window.setNeedsLayout()
		// We need the layout to happen naturally now.
		pumpRunLoopABit()

		self.verifyView(
			wrapper.container,
			identifier: [
				identifier,
				fitSize.width > 0 ? String(format: "w%.f", fitSize.width) : nil,
				fitSize.height > 0 ? String(format: "h%.f", fitSize.height) : nil
			].compactMap { $0 }.joined(separator: "_"),
			suffixes: self.referenceFolderSuffixes(),
			tolerance: 0.05
		)
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
