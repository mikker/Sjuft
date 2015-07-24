import Foundation
import Dispatcher

public struct Action {
    public typealias CallbackFn = ((Action -> Void) -> Void)
    
    public let type: Any?
    public let payload: Any?
    public let callbackFn: CallbackFn?

    public init(_ type: Any?, payload: Any? = nil, _ fn: CallbackFn? = nil) {
        self.type = type
        self.payload = payload
        self.callbackFn = fn
    }
}

public struct Store<StateType> {
    public typealias ReduceFn = (state: StateType, action: Action) -> StateType
    
    public let reducer: ReduceFn
    public init(_ reducer: ReduceFn) {
        self.reducer = reducer
    }
}

public class Sjuft<StateType> {
    public var dispatcher: Dispatcher
    public var stores: [Store<StateType>]
    public var state: StateType {
        didSet { notifyStateListeners(state) }
    }

    private var stateListeners: [String: StateType -> Void] = [:]
    private var actionListeners: [String: Action -> Void] = [:]

    public init(dispatcher: Dispatcher = Dispatcher(),
        initialState: StateType,
        stores: [Store<StateType>] = []) {
            
        self.dispatcher = dispatcher
        self.stores = stores
        self.state = initialState
        
        registerSelf()
    }

    public func dispatch(action: Action) {
        debugPrint("Sjuft: [\(action)]")
        
        if let asyncFn = action.callbackFn {
            asyncFn(self.dispatch)
        } else {
            dispatcher.dispatch(action)
        }
    }
    
    public func dispatch(notification: NSNotification) {
        let action = Action(notification)
        dispatcher.dispatch(action)
    }

    public func listen(handler: StateType -> Void) -> String {
        guard let token = dispatcher.tokenGenerator.next() else {
            preconditionFailure("Failed to generate token")
        }
        stateListeners[token] = handler
        handler(state)
        return token
    }
    
    public func unlisten(token: String) {
        stateListeners.removeValueForKey(token)
    }
    
    public func register(handler: (action: Action) -> Void) -> String {
        guard let token = dispatcher.tokenGenerator.next() else {
            preconditionFailure("Failed to generate token")
        }
        actionListeners[token] = handler
        return token
    }
    
    public func unregister(token: String) {
        actionListeners.removeValueForKey(token)
    }

    private func registerSelf() {
        self.dispatcher.register { action in
            guard let action = action as? Action else { return }

            self.state = self.stores.reduce(self.state) { state, store in
                store.reducer(state: state, action: action)
            }

            self.notifyActionListeners(action)
        }
    }
    
    private func notifyActionListeners(action: Action) {
        for listener in actionListeners.values {
            listener(action)
        }
    }

    private func notifyStateListeners(state: StateType) {
        for listener in stateListeners.values {
            listener(state)
        }
    }
}