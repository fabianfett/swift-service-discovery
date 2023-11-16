//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftServiceDiscovery open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftServiceDiscovery project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftServiceDiscovery project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Provides service instances lookup..
public protocol ServiceDiscovery: Sendable {
    /// Service discovery instance type
    associatedtype Instance: Sendable
    /// Service discovery subscription type
    associatedtype Subscription: ServiceDiscoverySubscription where Subscription.Instance == Instance

    /// Performs async lookup for the given service's instances.
    ///
    /// - Returns: A listing of service discovery instances.
    /// - throws when failing to lookup instances
    func lookup() async throws -> [Instance]

    /// Subscribes to receive service discovery change notification whenever service discovery instances change.
    /// 
    /// - Returns: An ``AsyncSequence`` of changes in the service discovery instances.
    /// - throws when failing to establish subscription
    func subscribe() async throws -> Subscription
}

/// The ``ServiceDiscoverySubscription`` constraints the AsyncSequence protocol:
/// The Element type must be a Swift Result of either the discovered Instances or an interim subscription
/// error. The ServiceDiscoverySubscription returns Results (instead of throwing) to express that subscription
/// errors might happen but do not signal a terminal state for the subscription.
///
/// Clients should decide how to best handle subscription errors, e.g. terminate
/// the subscription or continue and handle the errors, for example by recording or
/// propagating them.
///
/// - Warning: If clients terminate because of errors in the service discovery subscription, an outage in
///            the service backing the service discovery can have a significant blast radius. Consider the
///            service discovery SLOs and your own SLOs when deciding to terminate the client based on
///            an error in the service discovery subscription. \
///            \
///            We generally advice to keep your client running, if it can continue to handle requests, even
///            if the service discovery service is unresponsive for some time.
public protocol ServiceDiscoverySubscription: AsyncSequence, Sendable where Element == Result<[Instance], Error>, DiscoveryIterator == AsyncIterator {
    /// Service discovery instance type
    associatedtype Instance: Sendable

    associatedtype DiscoveryIterator: ServiceDiscoverySubscriptionIterator

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> DiscoveryIterator
}

/// The ``ServiceDiscoverySubscriptionIterator`` constraints an AsyncIteratorProtocol further:
/// The call to next must not throw but instead return a Swift Result of either the discovered Instances or 
/// an interim subscription error.
public protocol ServiceDiscoverySubscriptionIterator: AsyncIteratorProtocol where Element == Result<[Instance], Error> {
    associatedtype Instance

    mutating func next() async -> Result<[Instance], Error>?
}
