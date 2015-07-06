import Foundation

// lib

public protocol ActionConstant {}
public protocol AppState {}
public protocol Store {
    func reduce(state: AppState, action: Action) -> AppState
}
public protocol Dispatchable {}

public struct Action: Dispatchable {
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

public struct AsyncAction: Dispatchable {
    public let dispatchFn: (Dispatchable -> Void) -> Void
    public init(_ fn: (Dispatchable -> Void) -> Void) {
        self.dispatchFn = fn
    }
}

public class Flux {
    public var dispatcher: Dispatcher
    public var stores: [Store]
    public var state: AppState {
        didSet { notifyListeners() }
    }
    
    private var listeners: [AppState -> Void] = []
    
    public init(dispatcher: Dispatcher = Dispatcher(), initialState: AppState, stores: [Store] = []) {
        self.dispatcher = dispatcher
        self.stores = stores
        self.state = initialState
        
        register()
    }
    
    public func dispatch(dispatchable: Dispatchable) {
        switch dispatchable {
        case is Action:
            dispatcher.dispatch(dispatchable)
        case is AsyncAction:
            (dispatchable as! AsyncAction).dispatchFn(self.dispatch)
        default: ()
        }
    }
    
    public func listen(handler: AppState -> Void) {
        listeners.append(handler)
    }
    
    private func register() {
        self.dispatcher.register { action in
            if let action = action as? Action {
                self.state = self.stores.reduce(self.state) { state, store in
                    return store.reduce(state, action: action)
                }
            }
        }
    }
    
    private func notifyListeners() {
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

flux.listen { state in
    print("update:\(state)")
}

flux.dispatch(CounterActions.increment())
flux.dispatch(Action(Actions.DecrementCounter))
flux.dispatch(CounterActions.set(5))
flux.dispatch(CounterActions.async(666))

print("final: \(flux.state)")

CFRunLoopRun()