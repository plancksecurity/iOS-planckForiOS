//: Playground - noun: a place where people can play

import Foundation

class StateMachine<T: Hashable, U: Hashable> {
    typealias DidEnterStateBlock = () -> ()

    class TransitionIndex: Hashable {
        let source: T
        let input: U

        init(source: T, input: U) {
            self.source = source
            self.input = input
        }

        var hashValue: Int {
            return 31 &* source.hashValue &* input.hashValue
        }

        static func ==(lhs: TransitionIndex, rhs: TransitionIndex) -> Bool {
            return lhs.source == rhs.source && lhs.input == rhs.input
        }
    }

    var currentState: T
    var stateEventTable = [TransitionIndex: T]()
    var stateExecutionBlocks = [T: DidEnterStateBlock]()

    init(currentState: T) {
        self.currentState = currentState
    }

    func add(transitionIndex: TransitionIndex, target: T) {
        stateEventTable[transitionIndex] = target
    }

    func when(inState: T, onInput: U, transitTo: T) {
        let ti = TransitionIndex(source: inState, input: onInput)
        add(transitionIndex: ti, target: transitTo)
    }

    func executeAfterEntering(state: T, block: @escaping DidEnterStateBlock) {
        stateExecutionBlocks[state] = block
    }

    func start() {
        executeActionForCurrentState()
    }

    func executeActionForCurrentState() {
        if let action = stateExecutionBlocks[currentState] {
            action()
        }
    }

    func accept(input: U) -> Bool {
        let ti = TransitionIndex(source: currentState, input: input)
        if let newState = stateEventTable[ti] {
            currentState = newState
            executeActionForCurrentState()
            return true
        }
        return false
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
    case repeatSync
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

let machine: StateMachine<InboxSyncState, InboxSyncInput> = StateMachine(currentState: InboxSyncState.fetchingFolders)

machine.when(inState: .fetchingFolders, onInput: .fetchingFoldersDone, transitTo: .fetchingMessages)
machine.when(inState: .fetchingMessages, onInput: .fetchingMessagesDone, transitTo: .syncingMessages)
machine.when(inState: .syncingMessages, onInput: .syncingMessagesDone, transitTo: .idling)
machine.when(inState: .sendingSmtp, onInput: .sendingSmtpDone, transitTo: .sendingImap)
machine.when(inState: .sendingImap, onInput: .sendingImapDone, transitTo: .idling)
machine.when(inState: .savingDrafts, onInput: .savingDraftsDone, transitTo: .idling)
machine.when(inState: .idling, onInput: .repeatSync, transitTo: .syncingMessages)
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
print("* requesting another sync ...")
machine.accept(input: .repeatSync)
waitForState(machine: machine, state: .idling)
print("* requesting SMTP ...")
machine.accept(input: .sendSmtp)
waitForState(machine: machine, state: .idling)
print("* requesting draft save ...")
machine.accept(input: .saveDrafts)
waitForState(machine: machine, state: .idling)

print("* finished ...")
