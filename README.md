# Sjuft

My second stab at Flux in Swift.

## Example

### Flux.swift

```swift
import Sjuft

struct State: AppState {
    var count: Int = 0
}

enum Actions: ActionConstant {
    case IncrementCounter
    case DecrementCounter
    case SetCounter
}

struct CounterActions {
    static func increment() -> Action {
        return Action(Actions.IncrementCounter)
    }
    static func decrement() -> Action {
        return Action(Actions.DecrementCounter)
    }
    static func set(count: Int) -> Action {
        return Action(Actions.SetCounter, count)
    }
    static func async(count: Int) -> AsyncAction {
        return AsyncAction({ dispatch in
            dispatch_after(1, dispatch_get_main_queue()) { () -> Void in
                dispatch(self.set(count))
            }
        })
    }
}

struct CounterStore: Store {
    func reduce(state: AppState, action: Action) -> AppState {
        var state = state as! State

        switch action.type {
        case Actions.IncrementCounter:
            state.count += 1
        case Actions.DecrementCounter:
            state.count -= 1
        case Actions.SetCounter:
            state.count = action.payload as! Int
        default: ()
        }

        return state
    }
}

let flux = Flux(initialState: State(), stores: [CounterStore()])
```

### ViewController.swift

```swift
class ViewController: UIViewController {

    @IBOutlet weak var counterLabel: UILabel!

    var token: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.token = flux.listen { state in
            if let state = state as? State {
                self.counterLabel.text = String(state.count)
            }
        }
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
