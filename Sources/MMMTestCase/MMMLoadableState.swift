//
// MMMTestCase. Part of MMMTemple.
// Copyright (c) 2022 MediaMonks. All rights reserved.
// 

import MMMLoadable

extension MMMLoadableState {
	/// A dictionary with all states suitable for `MMMTestCase.varyParameters(_:block:)`
	/// (keys are kebab-case already).
	public private(set) static var allCasesDictionary: [String: MMMLoadableState] = [
		"idle": .idle,
		"syncing": .syncing,
		"did-fail-to-sync": .didFailToSync,
		"did-sync-successfully": .didSyncSuccessfully
	]
}
