//
// MMMTestCase. Part of MMMTemple.
// Copyright (C) 2015-2020 MediaMonks. All rights reserved.
//

import XCTest
import MMMLoadable

/// Convenience for using XCTest's expectations with loadables.
///
/// You can use custom predicates that are evaluated whenever a loadable changes:
/// ```
/// wait(for: [ MMMLoadableExpectation(favorites) { $0.isContentsAvailable } ], timeout: 1)
/// ```
///
/// Or you can use one of convenience initializers:
/// ```
/// wait(for: [ MMMLoadableExpectation(contentsAvailableFor: favorites) ], timeout: 1)
/// ```
public class MMMLoadableExpectation: XCTestExpectation, MMMLoadableObserverProtocol {

	public typealias Predicate = (MMMPureLoadableProtocol) -> Bool

	public let loadable: MMMPureLoadableProtocol
	public var loadableObserver: MMMLoadableObserver?
	public let predicate: Predicate

	public init(
		_ loadable: MMMPureLoadableProtocol,
		label: String = "Predicate on ${}",
		predicate: @escaping Predicate
	) {

		self.loadable = loadable
		self.predicate = predicate

		let description = label.replacingOccurrences(of: "${}", with: "\(type(of: loadable))")
		super.init(description: description)

		loadable.addObserver(self)

		evaluate()
	}

	deinit {
		// XCTestCase is using a different thread when deallocating expectations it waits on,
		// let's avoid unsubscribing for now.
	}

	// MARK: - Convenience predicates

	// All these are easy enough to use via the designated initialize but added descriptions could help with messaging.

	public convenience init(contentsAvailableFor loadable: MMMPureLoadableProtocol) {
		self.init(loadable, label: "Contents available on ${}") { $0.isContentsAvailable }
	}

	public convenience init(didSyncSuccessfully loadable: MMMPureLoadableProtocol) {
		self.init(loadable, label: "${} is synced") { $0.loadableState == .didSyncSuccessfully }
	}

	public convenience init(didFailToSync loadable: MMMPureLoadableProtocol) {
		self.init(loadable, label: "${} failed to sync") { $0.loadableState == .didFailToSync }
	}

	public convenience init(syncing loadable: MMMPureLoadableProtocol) {
		self.init(loadable, label: "${} syncing") { $0.loadableState == .syncing }
	}

	/// Fulfilled when the loadable is not syncing. This is convenient when the test is going to evaluate
	/// the state separately once the loadable is not busy anymore.
	public convenience init(notSyncing loadable: MMMPureLoadableProtocol) {
		self.init(loadable, label: "${} is not syncing") { $0.loadableState != .syncing }
	}

	// MARK: -

	private func evaluate() {
		if predicate(loadable) {
			// This would stall in case evaluate() is called from init(), thus async.
			DispatchQueue.main.async {
				self.fulfill()
			}
		}
	}

	// MARK: - MMMLoadableObserverProtocol

	public func loadableDidChange(_ loadable: MMMPureLoadableProtocol) {
		evaluate()
	}
}
