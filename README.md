# RxStateMachine

A simple state machine implementation with an API shamelessly based upon [RxAutomaton](github.com/inamiy/RxAutomaton).

State transitions cause effects that can send a new input to the state machine, errors can be represented by new states and inputs.

## Example

```swift
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
    print("Disconnected")
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
```
