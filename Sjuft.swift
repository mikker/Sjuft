import Foundation
import Dispatcher

public protocol ActionConstant {}
public protocol AppState {}
public protocol Store {
    func reduce(state: AppState, action: Action) -> AppState
}
public protocol Dispatchable {}

public struct Action: Dispatchable {
    public let type: ActionConstant
    public let payload: Any?

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

    private var listeners: [String: AppState -> Void] = [:]

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

    public func listen(handler: AppState -> Void) -> String {
        if let token = dispatcher.tokenGenerator.next() {
            listeners[token] = handler
            handler(state)
            return token
        }
        
        preconditionFailure("Failed to generate token")
    }
    
    public func unlisten(token: String) {
        listeners.removeValueForKey(token)
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
        for listener in listeners.values {
            listener(state)
        }
    }
}


