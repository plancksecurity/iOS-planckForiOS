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

    func add(source: T, input: U, target: T) {
        let ti = TransitionIndex(source: source, input: input)
        add(transitionIndex: ti, target: target)
    }

    func executeOnEnter(state: T, block: @escaping DidEnterStateBlock) {
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
    case fetchFolders
    case fetchMessages
    case syncMessages
    case idle
    case sendSmtp
    case sendImap
    case saveDrafts
}

enum InboxSyncInput {
    case foldersFetched
    case messagesFetched

    case idle
    case sendMails
    case saveDrafts
    case repeatSync
}

func addFakeAction(
    machine: StateMachine<InboxSyncState, InboxSyncInput>,
    whenEnteringState: InboxSyncState, inputOnFinished: InboxSyncInput) {
    machine.executeOnEnter(state: whenEnteringState) {
        print("Executing: \(whenEnteringState)")
        DispatchQueue.global().async {
            sleep(1)
            machine.accept(input: inputOnFinished)
        }
    }
}

let machine: StateMachine<InboxSyncState, InboxSyncInput> = StateMachine(currentState: InboxSyncState.fetchFolders)

addFakeAction(machine: machine, whenEnteringState: .fetchFolders, inputOnFinished: .foldersFetched)
addFakeAction(machine: machine, whenEnteringState: .fetchMessages, inputOnFinished: .messagesFetched)

machine.add(source: .fetchFolders, input: .foldersFetched, target: .fetchMessages)
machine.add(source: .fetchMessages, input: .messagesFetched, target: .syncMessages)
machine.add(source: .idle, input: .repeatSync, target: .fetchFolders)

machine.start()

while machine.currentState != .syncMessages {
    //print("state \(machine.currentState)")
    Thread.sleep(forTimeInterval: 0.1)
}
print("finished state: \(machine.currentState)")
