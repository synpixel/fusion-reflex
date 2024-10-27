local Selector = require(script.Selector)

export type WithProducer<Producer> = { Producer: Producer, Selector: typeof(Selector) }

return { Selector = Selector }
