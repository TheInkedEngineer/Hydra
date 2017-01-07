//
//  Shared.swift
//  Hydra
//
//  Created by Daniele Margutti on 05/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

//
//  Commons.swift
//  Hydra
//
//  Created by Daniele Margutti on 22/12/2016.
//  Copyright © 2016 Daniele Margutti. All rights reserved.
//

import Foundation

/// Grand Central Dispatch Queues
/// This is essentially a wrapper around GCD Queues and allows you to specify a queue in which operation will be executed in.
///
/// More on GCD QoS info are available [here](https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html).
///
/// - background: Should we used when work takes significant time, such as minutes or hours. Work is not visible to the user, such as indexing, synchronizing, and backups. Focuses on energy efficiency.
/// - main: The serial queue associated with the application’s main thread.
/// - userInteractive: Should we used when work is virtually instantaneous (work that is interacting with the user, such as operating on the main thread, refreshing the user interface, or performing animations. If the work doesn’t happen quickly, the user interface may appear frozen. Focuses on responsiveness and performance).
/// - userInitiated: Should we used when work is nearly instantaneous, such as a few seconds or less (work that the user has initiated and requires immediate results, such as opening a saved document or performing an action when the user clicks something in the user interface. The work is required in order to continue user interaction. Focuses on responsiveness and performance).
/// - utility: Should we used when work takes a few seconds to a few minutes (work that may take some time to complete and doesn’t require an immediate result, such as downloading or importing data. Utility tasks typically have a progress bar that is visible to the user. Focuses on providing a balance between responsiveness, performance, and energy efficiency).
/// - custom: provide a custom queue
public enum Context {
	case background
	case main
	case userInteractive
	case userInitiated
	case utility
	case custom(queue: DispatchQueue)
	
	public var queue: DispatchQueue {
		switch self {
		case .background:
			return DispatchQueue.global(qos: .background)
		case .main:
			return DispatchQueue.main
		case .userInteractive:
			return DispatchQueue.global(qos: .userInteractive)
		case .userInitiated:
			return DispatchQueue.global(qos: .userInitiated)
		case .utility:
			return DispatchQueue.global(qos: .utility)
		case .custom(let queue):
			return queue
		}
	}
}

public enum PromiseError: Error {
	case invalidInput
	case timeoutFired
	case predicateRejected
	case awaitOnMainQueue
}

public enum State<R> {
	case pending
	case fulfilled(value: R)
	case rejected(error: Error)
	
	public var isPending: Bool {
		guard case .pending = self else { return false }
		return true
	}
	
	public var error: Error? {
		guard case .rejected(let err) = self else { return nil }
		return err
	}
	
	public var value: R? {
		guard case .fulfilled(let value) = self else { return nil }
		return value
	}
}

public enum Observer<R> {
	case whenFulfilled(context: Context, handler: (R) -> ())
	case whenRejected(context: Context, handler: (Error) -> ())
	
	func fulfill(value: R) {
		guard case .whenFulfilled(let ctx, let fulfillHandler) = self else {
			return
		}
		ctx.queue.async(execute: {
			fulfillHandler(value)
		})
	}
	
	func reject(error: Error) {
		guard case .whenRejected(let ctx, let errorHandler) = self else {
			return
		}
		ctx.queue.async(execute: {
			errorHandler(error)
		})
	}
}
