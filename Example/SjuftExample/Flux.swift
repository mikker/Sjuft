import Sjuft

func delay(secs: Double, then: () -> Void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, Int64(secs * Double(NSEC_PER_SEC))),
        dispatch_get_main_queue(), then
    )
}

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
            delay(10) {
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