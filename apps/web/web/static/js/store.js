import { createStore, combineReducers } from 'redux'

import { location } from './state/location'
import { networks } from './state/networks'

let rootReducer = combineReducers({
  location,
  networks,
})

export const store = createStore(rootReducer)

console.log('state', store.getState())
store.subscribe(() => console.log('state', store.getState()))
