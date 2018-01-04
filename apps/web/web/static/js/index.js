import React from 'react'
import ReactDOM from 'react-dom'
import { App } from './components/App.jsx'
import { store } from './store'
import { Provider } from 'react-redux'
import { refreshNetworks } from './state_fetchers/networks'
import { refreshNodes } from './state_fetchers/nodes'

let react_root = document.getElementById('react-root')

if(react_root) {
  ReactDOM.render(<Provider store={store}><App /></Provider>, react_root)
}

refreshNetworks()
setInterval(refreshNetworks, 30000)

refreshNodes()
setInterval(refreshNodes, 30000)

let counter = 0
store.subscribe(() => {
  let store_counter = store.getState().counter

  if(store_counter > counter) {
    counter = store_counter
    refreshNodes()
    refreshNetworks()
  }
})
