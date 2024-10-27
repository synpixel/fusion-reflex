--[[
    MIT License

    Copyright (c) 2023-present Richard

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the “Software”), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

--[[
	A Producer is a state container that exposes a set of dispatchers that can
	be used to modify the state. The state is immmutable, so dispatchers return
	a new state object.
]]
export type Producer<State = any, Dispatchers = { [string]: (...any) -> State }> = Dispatchers & {
	--[[
		Returns the current state of the producer. Receives an optional selector
		function that can be used to select a subset of the state.
	]]
	getState: ((self: Producer<State, Dispatchers>) -> State)
		& (<Selection>(self: Producer<State, Dispatchers>, selector: (state: State) -> Selection) -> Selection),

	--[[
		Sets the state of the producer to a shallow copy of the given state.
		Fires listeners on the next frame.
	]]
	setState: (self: Producer<State, Dispatchers>, state: State) -> (),

	--[[
		Resets the state of the producer to the initial state. Fires listeners
		on the next frame if the state has changed.
	]]
	resetState: (self: Producer<State, Dispatchers>) -> (),

	--[[
		Returns the dispatchers for the actions passed to `createProducer`.
	]]
	getDispatchers: (self: Producer<State, Dispatchers>) -> Dispatchers,

	--[[
		Returns the original action functions passed to `createProducer`.
	]]
	getActions: (self: Producer<State, Dispatchers>) -> {
		[string]: (state: State, ...any) -> any,
	},

	--[[
		Returns a distinct copy of the producer. The new copy starts with the
		same state and actions, but functions independently.
	]]
	clone: (self: Producer<State, Dispatchers>) -> Producer<State, Dispatchers>,

	--[[
		Flushes any pending updates by calling listeners immediately.
	]]
	flush: (self: Producer<State, Dispatchers>) -> (),

	--[[
		Subscribes to changes in a specific part of the state. State updates
		are deferred until the next frame after all state updates have been
		processed.
	]]
	subscribe: ((self: Producer<State, Dispatchers>, listener: (state: State, prevState: State) -> ()) -> () -> ())
		& (<Selection>(
			self: Producer<State, Dispatchers>,
			selector: (state: State) -> Selection,
			listener: (state: Selection, prevState: Selection) -> ()
		) -> () -> ())
		& <Selection>(
			self: Producer<State, Dispatchers>,
			selector: (state: State) -> Selection,
			predicate: (state: Selection, prevState: Selection) -> boolean,
			listener: (state: Selection, prevState: Selection) -> ()
		) -> () -> (),

	--[[
		Similar to `subscribe`, but the listener is disconnect after the first
		time it is called.
	]]
	once: (<Selection>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> Selection,
		listener: (state: Selection, prevState: Selection) -> ()
	) -> () -> ()) & <Selection>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> Selection,
		predicate: ((state: Selection, prevState: Selection) -> boolean)?,
		listener: (state: Selection, prevState: Selection) -> ()
	) -> () -> (),

	--[[
		Returns a Promise that resolves once a specific part of the state changes.
		Unsubscribes the listener if the Promise is cancelled or resolved.

		Receives an optional `predicate` function that must return `true` for the
		Promise to resolve for a given state change.
	]]
	wait: <Selection>(
		self: Producer<State, Dispatchers>,
		selector: ((state: State) -> Selection)?,
		predicate: ((state: Selection, prevState: Selection) -> boolean)?
	) -> any,

	--[[
		Tracks the addition and removal of items in an array. Calls the given
		observer for each added item and calls the cleanup function when the
		item is removed.

		If your array contains immutable objects, you can use the `discriminator`
		argument to return a unique identifier for each item. This allows the
		observer to avoid calling the observer for items that have already been
		added.
	]]
	observe: (<K, V>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> { [K]: V },
		discriminator: ((item: V, index: K) -> unknown)?,
		observer: (item: V, index: K) -> (() -> ())?
	) -> () -> ()) & (<K, V>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> { [K]: V },
		observer: (item: V, index: K) -> (() -> ())?
	) -> () -> ()),

	--[[
		Similar to `observe`, but it creates one observer while a selector or
		predicate is truthy, and destroys the observer when it's no longer truthy.
	]]
	observeWhile: (<T>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> T,
		predicate: (state: T, prevState: T) -> boolean,
		observer: (state: T) -> (() -> ())?
	) -> () -> ()) & (<T>(
		self: Producer<State, Dispatchers>,
		selector: (state: State) -> T?,
		observer: (state: T) -> (() -> ())?
	) -> () -> ()),

	--[[
		Disconnects all listeners and cancels all pending flushes.
	]]
	destroy: (self: Producer<State, Dispatchers>) -> (),

	--[[
		Enhances the producer with new functionality. The enhancer function
		is passed to the producer as an argument and should mutate the producer
		in place.
	]]
	enhance: <Enhanced>(self: Producer<State, Dispatchers>, enhancer: (producer: any) -> Enhanced) -> Enhanced,

	--[[
		Applies the given middlewares to the producer and its dispatchers. Returns
		the producer for chaining.

		Initially, a middleware is called once when it is applied to a producer.
		Next, the returned function is called on a dispatcher in the producer.
		The final function is called whenever the dispatcher is called.
	]]
	applyMiddleware: (
		self: Producer<State, Dispatchers>,
		...(producer: any) -> (dispatch: (...any) -> any, name: string) -> (...any) -> any
	) -> Producer<State, Dispatchers>,
}

--[[
	A middleware is a function that is called before an action is dispatched.

	Initially, a middleware is called once when it is applied to a producer.
	Next, the returned function is called on a dispatcher in the producer.
	The final function is called whenever that dispatcher is called.
]]
export type Middleware = (producer: Producer) -> (dispatch: (...any) -> any, name: string) -> (...any) -> any

export type ProducerMap = { [string]: Producer }

--[[
	A container for storing a Reflex dispatcher's name and arguments.
]]
export type BroadcastAction = {
	name: string,
	arguments: {},
}

--[[
	Options for the broadcast middleware.
]]
export type BroadcasterOptions = {
	--[[
		The producers that will be tracked.
	]]
	producers: ProducerMap,

	--[[
		The rate in seconds at which the server should hydrate the
		clients with the latest state.
	]]
	hydrateRate: number?,

	--[[
		The rate in seconds at which the server should dispatch
		actions to the clients. If set to `0`, actions will be
		dispatched within the next frame.
	]]
	dispatchRate: number?,

	--[[
		Runs before actions are dispatched to a player. Can be used to
		filter actions or manipulate them before sending.

		Avoid directly mutating the action. Instead, return a new action
		if you need to change it. Return `nil` to not share the action
		with this player.
	]]
	beforeDispatch: ((player: Player, action: BroadcastAction) -> BroadcastAction?)?,

	--[[
		Runs before the client is hydrated with the latest state. Can be
		used to filter the state or hide certain values from the client.

		Do not mutate the state in this function! Treat it as a read-only
		object, and return a new object if you need to change it.
	]]
	beforeHydrate: ((player: Player, state: { [string]: any }) -> { [string]: any })?,

	--[[
		An optional custom hydration function. If provided, this function
		will be called instead of being implicitly handled in 'dispatch'.

		Useful for reducing load on a single remote if your state is large.
	]]
	hydrate: ((player: Player, state: { [string]: any }) -> ())?,

	--[[
		The function that will send the actions to the client.
	]]
	dispatch: (player: Player, actions: { BroadcastAction }) -> (),
}

--[[
	Options for the broadcast receiver.
]]
export type BroadcastReceiverOptions = {
	--[[
		A function that, when called, should fire a remote that calls
		`start(player)` on the server broadcaster.
	]]
	start: () -> any,
}

--[[
	A broadcaster that can be used to share actions with the client.
]]
export type Broadcaster = {
	--[[
		The middleware that will broadcast actions to the client.
	]]
	middleware: Middleware,

	--[[
		Starts broadcasting state and actions to the given player.
	]]
	start: (self: Broadcaster, player: Player) -> (),

	--[[
		Disconnects all listeners and cancels all pending dispatches.
	]]
	destroy: (self: Broadcaster) -> (),
}

--[[
	A receiver that can be used to dispatch actions broadcasted by the server.
]]
export type BroadcastReceiver = {
	--[[
		A middleware that should be applied to the root producer. This will
		merge the producer's state with the server's state on join.
	]]
	middleware: Middleware,

	--[[
		Dispatches actions broadcasted by the server.
	]]
	dispatch: (self: BroadcastReceiver, actions: { BroadcastAction }) -> (),

	--[[
		Hydrates the client with the latest state from the server.
		Normally, hydration is implicitly handled in 'dispatch' unless a
		custom hydration handler is provided in the broadcaster options.

		Useful for reducing load on a single remote if your state is large.
	]]
	hydrate: (self: BroadcastReceiver, state: { [string]: any }) -> (),
}

return nil
