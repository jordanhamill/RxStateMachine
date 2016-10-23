import Foundation
import RxSwift

public enum TransitionResult<State, Input> {
    case success(old: State, new: State, input: Input)
    case failure(currentState: State, input: Input)
}

public class StateMachine<State, Input> {

    public typealias StateMapping = StateMappingWithEffect<State, Input>
    public typealias StateMapResult = (state: State, effect: StateMappingWithEffect<State, Input>.Effect)?

    // MARK: Public properties

    public let currentState: ReadOnlyVariable<State>
    public let transitionResult: Observable<TransitionResult<State, Input>>

    // MARK: Private properties

    private let stateMapping: (State, Input) -> StateMapResult
    private let transitionResultSubject: PublishSubject<TransitionResult<State, Input>>
    private let lock = NSRecursiveLock()

    // MARK: Object lifecycle

    public convenience init(initialState: State, mappings: [StateMapping]) {
        let reduced: (State, Input) -> StateMapResult = { currentState, input in
            for mappingWithEffect in mappings {
                let mapping = mappingWithEffect.mapping
                if mapping.inputMatches(input) && mapping.transition.currentStateMatches(currentState) {
                    return (mapping.transition.nextState, mappingWithEffect.effect)
                }
            }

            return nil
        }
        self.init(initialState: initialState, stateMapping: reduced)
    }

    public init(initialState: State, stateMapping: @escaping (State, Input) -> StateMapResult) {
        self.currentState = Variable(initialState).readOnly()
        self.stateMapping = stateMapping

        self.transitionResultSubject = PublishSubject()
        self.transitionResult = transitionResultSubject.asObservable()
    }

    // MARK: Public methods

    public func send(input: Input) {
        lock.lock(); defer { lock.unlock() }

        let currentState = self.currentState.value
        guard let nextState = stateMapping(currentState, input) else {
            transitionResultSubject.onNext(.failure(currentState: currentState, input: input))
            return
        }

        self.currentState.readWrite.value = nextState.0
        transitionResultSubject.onNext(.success(old: currentState, new: nextState.0, input: input))
        nextState.effect(input, self.send)
    }
}
