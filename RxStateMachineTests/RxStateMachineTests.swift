import RxStateMachine
import RxSwift
import XCTest

class RxStateMachineTests: XCTestCase {
    func testExample() {

        let itWorks = expectation(description: "It works")

        enum MyInputs {
            case connect
            case connectOk
            case disconnect
            case disconnectOk
        }

        enum MyStates {
            case disconnected
            case connecting
            case connected
            case disconnecting
        }

        func connect(send: @escaping (MyInputs) -> Void) {
            DispatchQueue.global().async {
                send(.connectOk)
            }
        }

        func disconnect(send: (MyInputs) -> Void) {
            send(.disconnectOk)
        }

        func noEffect(send: (MyInputs) -> Void) { }

        func onDisconnected(send: (MyInputs) -> Void) {
            itWorks.fulfill()
        }

        let machine = StateMachine<MyStates, MyInputs>(initialState: .disconnected,
        mappings: [
            /* Input      |      from              to         |   effect    */
            .connect      | .disconnected  =>  .connecting    | connect,
            .connectOk    | .connecting    =>  .connected     | noEffect,
            .disconnect   | .connected     =>  .disconnecting | disconnect,
            .disconnectOk | .disconnecting =>  .disconnected  | onDisconnected
        ])

        let disposeBag = DisposeBag()
        machine.currentState.asObservable()
            .filter { $0 == .connected }
            .delay(2, scheduler: MainScheduler.instance)
            .subscribe(onNext: { state in
                machine.send(input: .disconnect)
            })
            .addDisposableTo(disposeBag)

        machine.send(input: .connect)

        waitForExpectations(timeout: 5, handler: nil)
    }
}
