# Sjuft

My second stab at Flux in Swift.

## Example

### Flux.swift

```swift
import Sjuft

struct State {
    var count = 0
}

enum Constants {
    case IncrementCounter
    case DecrementCounter
    case SetCounter
}

struct CounterActions {
    static func increment() -> Action {
        return Action(Constants.IncrementCounter)
    }
    static func decrement() -> Action {
        return Action(Constants.DecrementCounter)
    }
    static func set(count: Int) -> Action {
        return Action(Constants.SetCounter, payload: count)
    }
    static func async(count: Int) -> Action {
        return Action(nil, payload: nil, { dispatch in
            delay(10) {
                dispatch(self.set(count))
            }
        })
    }
}

let counterStore = Store { (var state, action) -> State in
    switch action.type! {
    case Constants.IncrementCounter:
        state.count += 1
    case Constants.DecrementCounter:
        state.count -= 1
    case Constants.SetCounter:
        state.count = action.payload as! Int
    default: ()
    }

    return state
}

func delay(secs: Double, then: () -> Void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, Int64(secs * Double(NSEC_PER_SEC))),
        dispatch_get_main_queue(), then
    )
}

let flux = Sjuft(initialState: State(), stores: [counterStore])
```

### ViewController.swift

```swift
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var counterLabel: UILabel!

    var token: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.token = flux.listen { state in
            self.counterLabel.text = String(state.count)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        flux.dispatch(CounterActions.async(666))
    }

    deinit {
        flux.unlisten(token)
    }

    @IBAction func increment(sender: AnyObject?) {
        flux.dispatch(CounterActions.increment())
    }

    @IBAction func decrement(sender: AnyObject?) {
        flux.dispatch(CounterActions.decrement())
    }

}
```
