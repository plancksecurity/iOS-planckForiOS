//: Playground - noun: a place where people can play

import Foundation

open class MutableOrderedSet<T>: Sequence {
    public init() {}

    public init(array: [T]) {
        for e in array {
            elements.add(e)
        }
    }

    open var array: [T] {
        return elements.array as? [T] ?? []
    }

    open subscript(safe index: Int) -> T? {
        get {
            if elements.count == 0 {
                return nil
            }
            if index >= elements.count {
                return nil
            }
            if let e = elements.object(at: index) as? T {
                return e
            }
            return nil
        }
    }

    open var count: Int {
        get {
            return elements.count
        }
    }

    open var isEmpty: Bool {
        get {
            return elements.count == 0
        }
    }

    open func append(_ element: T) {
        elements.add(element)
    }

    open func insert(_ element: T) {
        self.append(element)
    }

    open func contains(_ element: T) -> Bool {
        return elements.contains(element)
    }

    open func remove(_ element: T) {
        elements.remove(element)
    }

    open func indexOf(_ element: T) -> Int? {
        let i = elements.index(of: element)
        if i == NSNotFound {
            return nil
        } else {
            return i
        }
    }

    private var elements = NSMutableOrderedSet()

    // MARK: - Sequence

    public typealias Iterator = MutableOrderedSetIterator<T>

    public func makeIterator() -> MutableOrderedSet.Iterator {
        return MutableOrderedSetIterator.init(elements: elements.array as! [T])
    }
}

public struct MutableOrderedSetIterator<T>: IteratorProtocol {
    public typealias Element = T

    private let elements: [T]
    private var index = 0
    private let maxIndex: Int

    public init(elements: [T]) {
        self.elements = elements
        maxIndex = elements.count - 1
    }

    public mutating func next() -> MutableOrderedSetIterator.Element? {
        if index > maxIndex {
            return nil
        } else {
            let e = elements[index]
            index += 1
            return e
        }
    }
}

class StateMachine<T: Equatable> {
    class State<T: Equatable>: Equatable {
        let value: T
        let didChangeToBlock: (() -> (Void))?

        init(value: T, changedTo: (() -> (Void))? = nil) {
            self.value = value
            self.didChangeToBlock = changedTo
        }

        public static func ==(lhs: State, rhs: State) -> Bool {
            return lhs.value == rhs.value
        }
    }

    class Input<T: Equatable> {
        let name: String
        let from: State<T>
        let to: State<T>

        init(name: String, from: State<T>, to: State<T>) {
            self.name = name
            self.from = from
            self.to = to
        }
    }

    enum InputError: Error {
        /**
         An input was denied, because the current state does not match the source
         state of the input.
         */
        case inputDenied
    }
    
    var states = MutableOrderedSet<State<T>>()
    var eventsByName = [String: Input<T>]()
    var currentState: State<T>

    init(states: [State<T>], startingState: State<T>) {
        self.states = MutableOrderedSet(array: states)
        currentState = startingState
        signalActivation(state: currentState)
    }

    func input(_ input: Input<T>) throws {
        if input.from != currentState {
            throw InputError.inputDenied
        }

        currentState = input.to
        signalActivation(state: currentState)
    }

    func signalActivation(state: State<T>) {
        if let fn = state.didChangeToBlock {
            fn()
        }
    }
}

enum InboxSyncState {
    case fetchFolders
    case fetchMessages
    case syncMessages
    case idle
    case sendSmtp
    case sendImap
    case saveDrafts
}

let inboxStartState: StateMachine.State<InboxSyncState>? = nil //= StateMachine<InboxSyncState>.State(value: .fetchFolders)

/*
let inboxSyncStates = [
    inboxStartState
]
*/
