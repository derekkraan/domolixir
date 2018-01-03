import React from 'react'
import { connect } from 'react-redux'
import { Layout } from './Layout.jsx'
import { Field } from './Fields.jsx'

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
  <p>Network</p>
</div>

const Node = ({node}) => <div className="node">
  <p>Node</p>
  <p>{ node.node_identifier }</p>
  <div>
    { node.commands.map((commandTemplate) => <Command node={node} commandTemplate={commandTemplate} />) }
  </div>
</div>

class Command extends React.Component {
  constructor(props) {
    super(props)
    console.log(props)
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
    fetch('/node/command', {
      method: "post",
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': csrfToken(),
      },
      credentials: 'same-origin',
      body: JSON.stringify({
        node_identifier: this.props.node.node_identifier,
        command: this.formatCommand(),
      })
    })
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
  <form onSubmit={onSubmit}>
    { commandTemplate.slice(1).map((field, i) => <Field field={field} onChange={(val) => setProperty(i, val)} value={command[i]}/>) }
    <button>
      { commandTemplate[0] }
    </button>
  </form>
</div>

const csrfToken = () => document.head.querySelector('meta[name=csrf]').content