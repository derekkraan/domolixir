import { createStore, combineReducers } from 'redux'

import { location } from './state/location'
import { networks } from './state/networks'
import { nodes } from './state/nodes'


const counter = (state = 0, action) => {
  if(action.type === "REFRESH_STATE") {
    return state + 1
  }
  return state
}

let rootReducer = combineReducers({
  location,
  networks,
  nodes,
  counter,
})

export const store = createStore(rootReducer)

console.log('store', store.getState())
store.subscribe(() => console.log('store', store.getState()))
