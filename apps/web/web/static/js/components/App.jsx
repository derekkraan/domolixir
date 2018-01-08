import React from 'react'
import { connect } from 'react-redux'
import { Layout } from './Layout.jsx'
import { Field, OnOffSlider } from './Fields.jsx'
import { t } from '../lib/translations'
import { store } from '../store'

const mapStateToProps = ({nodes, networks}) => {
  return {
    nodes: Object.values(nodes),
    networks: Object.values(networks)
  }
}
const mapDispatchToProps = () => ({})

const AppView = ({nodes, networks}) => <Layout>
  { networks.map((network) => <Network network={network} key={network.network_identifier}/>) }
  { nodes.map((node) => <Node node={node} key={node.node_identifier} />) }
</Layout>

export const App = connect(
  mapStateToProps,
  mapDispatchToProps
)(AppView)

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

const Node = ({node}) => <div className={`node ${node.alive ? 'alive' : 'dead'}`}>
  <h2>Node { node.node_identifier }</h2>
  <div>
    { node.commands.filter((commandTemplate) => commandTemplate[0] !== 'turn_off' && commandTemplate[0] !== 'turn_on').map((commandTemplate) => <Command node={node} commandTemplate={commandTemplate} />) }
  </div>
  <div className="on_off_switch">
    <a href="" onClick={(e) => {executeCommandEvent(e, node, ['turn_off'])}}>OFF</a>
    <OnOffSlider value={node.on_off_status === 'on'} onChange={(on_off) => { executeCommand(node, [on_off ? 'turn_on' : 'turn_off'])}} />
    <a href="" onClick={(e) => {executeCommandEvent(e, node, ['turn_on'])}}>ON</a>
  </div>
</div>

const executeCommandEvent = (event, node, command) => {
  event.preventDefault()
  executeCommand(node, command)
}

const executeCommand = (node, command) => {
  fetch('/node/command', {
    method: "post",
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': csrfToken(),
    },
    credentials: 'same-origin',
    body: JSON.stringify({
      node_identifier: node.node_identifier,
      command: command,
    })
  }).then(() => {
    store.dispatch({type: "REFRESH_STATE"})
  })
}

const CommandList = ({commands}) => <select>
  { commands.map((command) => <option key={command[0]}>{command[0]}</option>) }
</select>

class Command extends React.Component {
  constructor(props) {
    super(props)
    this.state = {command: this.defaultValues(props.commandTemplate)}
  }

  setProperty (index, value) {
    let command = this.state.command.slice()
    command[index] = value
    this.setState({command: command})
  }

  defaultValues (commandTemplate) {
    return commandTemplate.slice(1).map((property) => {
      switch(property[1]) {
        case "float":
          return 0.5
        case "float_0_1":
          return 50
      }
      return 0
    })
  }

  onSubmit (e) {
    e.preventDefault()
    executeCommand(this.props.node, this.formatCommand())
  }

  formatCommand () {
    let command_pieces = [this.props.commandTemplate[0]]
    let rest_of_command = this.props.commandTemplate.slice(1).map(([name, field_type], i) => formatFieldForCommand(field_type, this.state.command[i]))
    return command_pieces.concat(rest_of_command)
  }

  render () {
    return <CommandView {...this.props} {...this.state} setProperty={this.setProperty.bind(this)} onSubmit={this.onSubmit.bind(this)} />
  }
}

const formatFieldForCommand = (field_type, value) => {
  switch(field_type) {
    case "float_0_1": return value / 100
  }
  return value
}

const CommandView = ({node, command, commandTemplate, setProperty, onSubmit}) => <div>
  <form onSubmit={onSubmit} className="command">
    <div className="fields">
      { commandTemplate.slice(1).map((field, i) => <Field field={field} onChange={(val) => setProperty(i, val)} value={command[i]}/>) }
    </div>
    <div className="buttons">
      <button>
        { t(`command.${commandTemplate[0]}`) }
      </button>
    </div>
  </form>
</div>

const csrfToken = () => document.head.querySelector('meta[name=csrf]').content
