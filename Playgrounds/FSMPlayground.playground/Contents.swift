//: Playground - noun: a place where people can play

import Foundation

/**
 T is the set of all states.
 U is the set of all inputs.
 Both T und U typically are of type `enum`.
 */
protocol StateMachineProtocol {
    typealias DidEnterStateBlock = () -> ()

    associatedtype T: Hashable
    associatedtype U: Hashable

    var currentState: T { get }

    /**
     Define a transition from one state to the next.
     */
    func when(inState: T, onInput: U, transitTo: T)

    /**
     Define an action that gets executed *after* the state has been entered.
     */
    func executeAfterEntering(state: T, block: @escaping DidEnterStateBlock)

    func start()

    func accept(input: U) -> Bool
}

class StateMachine<T: Hashable, U: Hashable>: StateMachineProtocol {
    var currentState: T

    init(startState: T) {
        self.currentState = startState
    }

    func when(inState: T, onInput: U, transitTo: T) {
        managementQueue.async {
            let ti = TransitionIndex(source: inState, input: onInput)
            self.add(transitionIndex: ti, target: transitTo)
        }
    }

    func executeAfterEntering(state: T, block: @escaping StateMachineProtocol.DidEnterStateBlock) {
        managementQueue.async {
            self.afterEnteringBlocks[state] = block
        }
    }

    func start() {
        managementQueue.async {
            self.executeActionForCurrentState()
        }
    }

    func accept(input: U) -> Bool {
        var result = false
        managementQueue.sync {
            let ti = TransitionIndex(source: currentState, input: input)
            if let newState = stateEventTable[ti] {
                currentState = newState
                executeActionForCurrentState()
                result = true
            }
            result = false
        }
        return result
    }

    // MARK - Private

    private struct TransitionIndex: Hashable {
        let source: T
        let input: U

        var hashValue: Int {
            return 31 &* source.hashValue &* input.hashValue
        }

        static func ==(lhs: TransitionIndex, rhs: TransitionIndex) -> Bool {
            return lhs.source == rhs.source && lhs.input == rhs.input
        }
    }

    private var stateEventTable = [TransitionIndex: T]()
    private var afterEnteringBlocks: [T: StateMachineProtocol.DidEnterStateBlock] = [:]
    private let managementQueue = DispatchQueue(
        label: "StateMachine.managemendQueue", qos: .utility, target: nil)

    private func add(transitionIndex: TransitionIndex, target: T) {
        managementQueue.async {
            self.stateEventTable[transitionIndex] = target
        }
    }

    private func executeActionForCurrentState() {
        if let action = afterEnteringBlocks[currentState] {
            action()
        }
    }
}

enum InboxSyncState {
    case fetchingFolders
    case fetchingMessages
    case syncingMessages
    case idling
    case sendingSmtp
    case sendingImap
    case savingDrafts
}

enum InboxSyncInput {
    case fetchingFoldersDone
    case fetchingMessagesDone
    case syncingMessagesDone
    case sendingSmtpDone
    case sendingImapDone
    case savingDraftsDone

    case idle
    case sendMails
    case saveDrafts
    case repeatFetch
    case sendSmtp
}

func addFakeAction(
    machine: StateMachine<InboxSyncState, InboxSyncInput>,
    whenEnteringState: InboxSyncState, inputOnFinished: InboxSyncInput) {
    machine.executeAfterEntering(state: whenEnteringState) {
        print("  Executing: \(whenEnteringState)")
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            machine.accept(input: inputOnFinished)
        }
    }
}

func waitForState(machine: StateMachine<InboxSyncState, InboxSyncInput>, state: InboxSyncState) {
    while machine.currentState != state {
        //print("state \(machine.currentState)")
        Thread.sleep(forTimeInterval: 0.1)
    }
    print("  > reached state: \(machine.currentState)")
}

let machine: StateMachine<InboxSyncState, InboxSyncInput> = StateMachine(startState: InboxSyncState.fetchingFolders)

machine.when(inState: .fetchingFolders, onInput: .fetchingFoldersDone, transitTo: .fetchingMessages)
machine.when(inState: .fetchingMessages, onInput: .fetchingMessagesDone, transitTo: .syncingMessages)
machine.when(inState: .syncingMessages, onInput: .syncingMessagesDone, transitTo: .idling)
machine.when(inState: .sendingSmtp, onInput: .sendingSmtpDone, transitTo: .sendingImap)
machine.when(inState: .sendingImap, onInput: .sendingImapDone, transitTo: .idling)
machine.when(inState: .savingDrafts, onInput: .savingDraftsDone, transitTo: .idling)
machine.when(inState: .idling, onInput: .repeatFetch, transitTo: .fetchingMessages)
machine.when(inState: .idling, onInput: .sendSmtp, transitTo: .sendingSmtp)
machine.when(inState: .idling, onInput: .saveDrafts, transitTo: .savingDrafts)

//////////////////////////
// Testing
//////////////////////////

addFakeAction(machine: machine, whenEnteringState: .fetchingFolders, inputOnFinished: .fetchingFoldersDone)
addFakeAction(machine: machine, whenEnteringState: .fetchingMessages, inputOnFinished: .fetchingMessagesDone)
addFakeAction(machine: machine, whenEnteringState: .syncingMessages, inputOnFinished: .syncingMessagesDone)
addFakeAction(machine: machine, whenEnteringState: .sendingSmtp, inputOnFinished: .sendingSmtpDone)
addFakeAction(machine: machine, whenEnteringState: .sendingImap, inputOnFinished: .sendingImapDone)
addFakeAction(machine: machine, whenEnteringState: .savingDrafts, inputOnFinished: .savingDraftsDone)

print("* starting machine ...")
machine.start()

waitForState(machine: machine, state: .idling)
print("* requesting another fetch/sync cycle ...")
machine.accept(input: .repeatFetch)
waitForState(machine: machine, state: .idling)
print("* requesting SMTP ...")
machine.accept(input: .sendSmtp)
waitForState(machine: machine, state: .idling)
print("* requesting draft save ...")
machine.accept(input: .saveDrafts)
waitForState(machine: machine, state: .idling)

print("* finished ...")
