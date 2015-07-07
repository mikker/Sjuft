import Foundation
import Dispatcher

public protocol Constant {}
public protocol State {}
public protocol Store {
    func reduce(state: State, action: Action) -> State
}

public struct Action {
    public typealias CallbackFn = ((Action -> Void) -> Void)
    
    public let type: Constant?
    public let payload: Any?
    public let callbackFn: CallbackFn?

    public init(_ type: Constant?, payload: Any? = nil, _ fn: CallbackFn? = nil) {
        self.type = type
        self.payload = payload
        self.callbackFn = fn
    }
}

public class Sjuft {
    public var dispatcher: Dispatcher
    public var stores: [Store]
    public var state: State {
        didSet { notifyListeners() }
    }

    private var listeners: [String: State -> Void] = [:]

    public init(dispatcher: Dispatcher = Dispatcher(), initialState: State, stores: [Store] = []) {
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

    public func listen(handler: State -> Void) -> String {
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


