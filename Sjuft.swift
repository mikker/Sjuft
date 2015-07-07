import Foundation
import Dispatcher

public protocol ActionConstant {}
public protocol AppState {}
public protocol Store {
    func reduce(state: AppState, action: Action) -> AppState
}

public struct Action {
    public typealias CallbackFn = ((Action -> Void) -> Void)
    
    public let type: ActionConstant
    public let payload: Any?
    public let callbackFn: CallbackFn?

    public init(_ type: ActionConstant, payload: Any? = nil, _ fn: CallbackFn? = nil) {
        self.type = type
        self.payload = payload
        self.callbackFn = fn
    }
}

public class Sjuft {
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

    public func dispatch(action: Action) {
        if let asyncFn = action.callbackFn {
            asyncFn(self.dispatch)
        } else {
            dispatcher.dispatch(action)
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


