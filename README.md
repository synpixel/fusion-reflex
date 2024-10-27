# Fusion Reflex

A port of [react-reflex](https://github.com/littensy/react-reflex) for Fusion 0.3

## Installing

### Pesde

```sh
pesde add synpixel/fusion_reflex
```

## Example

```lua
local scope = Fusion:scoped(FusionReflex, { Producer = producer })

local count = scope:Selector(function(state)
    return state.count
end)

scope:New "TextButton" {
    Text = scope:Computed(function(use)
		return `Count: {use(count)}`
	end),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0, 100, 0, 50),
	Position = UDim2.new(0.5, 0, 0.5, 0),
    Parent = playerGui,

	[Fusion.OnEvent "MouseButton1Click"] = function()
		scope.Producer.increment()
	end,

	[Fusion.OnEvent "MouseButton2Click"] = function()
		scope.Producer.decrement()
	end,
}
```
