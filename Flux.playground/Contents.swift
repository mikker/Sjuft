// lib

public protocol ActionConstant {}
public protocol AppState {}
public protocol Store {
    func reduce(state: AppState, action: Action) -> AppState
}

public struct Action {
    let type: ActionConstant
    let payload: Any?
    
    public init(_ type: ActionConstant) {
        self.type = type
        self.payload = nil
    }
    
    public init(_ type: ActionConstant, _ payload: Any?) {
        self.type = type
        self.payload = payload
    }
}

public class Flux {
    var state: AppState {
        didSet { notifyListeners() }
    }
    var dispatcher: Dispatcher
    var stores: [Store]
    
    private var listeners: [AppState -> Void] = []
    
    public init(dispatcher: Dispatcher = Dispatcher(), initialState: AppState, stores: [Store] = []) {
        self.dispatcher = dispatcher
        self.stores = stores
        self.state = initialState
        
        self.dispatcher.register { action in
            if let action = action as? Action {
                self.state = stores.reduce(self.state) { (state, store) -> AppState in
                    return store.reduce(state, action: action)
                }
            }
        }
    }
    
    public func dispatch(action: Action) {
        self.dispatcher.dispatch(action)
    }
    
    public func listen(handler: AppState -> Void) {
        listeners.append(handler)
    }
    
    func notifyListeners() {
        for listener in listeners { listener(state) }
    }
}

// example

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
    static func set(count: Int) -> Action {
        return Action(Actions.SetCounter, count)
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

flux.listen { state in
    print("update:\(state)")
}

flux.dispatch(CounterActions.increment())
flux.dispatch(Action(Actions.DecrementCounter))
flux.dispatch(CounterActions.set(5))

print("final: \(flux.state)")