import { createStore, combineReducers } from 'redux'

import { location } from './state/location'
import { networks } from './state/networks'
import { nodes } from './state/nodes'

let rootReducer = combineReducers({
  location,
  networks,
  nodes,
})

export const store = createStore(rootReducer)

console.log('store', store.getState())
store.subscribe(() => console.log('store', store.getState()))
