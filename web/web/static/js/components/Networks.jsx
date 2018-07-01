import React from 'react'
import { connect } from 'react-redux'
import { t } from '../lib/translations'
import { store } from '../store'
import { csrfToken } from './Nodes.jsx'

const mapStateToProps = ({nodes, networks}) => {
  return {
    networks: Object.values(networks)
  }
}

const mapDispatchToProps = () => ({})

const NetworksView = ({networks}) => networks.map((network) => <Network network={network} key={network.network_identifier}/>)

export const Networks = connect(
  mapStateToProps,
  mapDispatchToProps
)(NetworksView)

const Network = ({network}) => <div className="network">
  <h2>{ t(`networks.${network.network_type}`) } { network.network_identifier }</h2>
  { network.paired ? 'Paired' : <Pair network={network} /> }
  { network.connected ? 'Connected' : <Connect network={network} /> }
</div>

const Pair = ({network}) => <form onSubmit={(e) => pairNetwork(e, network)}>
  <button>Pair</button>
</form>

const Connect = ({network}) => <form onSubmit={(e) => connectNetwork(e, network)}>
  <button>Connect</button>
</form>

const pairNetwork = (e, network) => {
  e.preventDefault()
  fetch('/network/pair', {
    method: 'post',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': csrfToken(),
    },
    credentials: 'same-origin',
    body: JSON.stringify({
      network_identifier: network.network_identifier,
    })
  }).then(() => {
    store.dispatch({type: "REFRESH_STATE"})
  })
}

const connectNetwork = (e, network) => {
  e.preventDefault()
  fetch('/network/connect', {
    method: 'post',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': csrfToken(),
    },
    credentials: 'same-origin',
    body: JSON.stringify({
      network_identifier: network.network_identifier,
    })
  }).then(() => {
    store.dispatch({type: "REFRESH_STATE"})
  })
}
