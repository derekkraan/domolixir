import React from 'react'

export class Terminal extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      history: [],
      output: [],
      bindings: {},
      inputValue: 'String.length("FOOBAR")',
    }
  }

  onEnter(e) {
    e.preventDefault()

    let headers = new Headers()

    fetch('/repl', {
      method: 'POST',
      credentials: 'same-origin',
      headers: headers,
      body: JSON.stringify({ input: this.state.inputValue, bindings: this.state.bindings }),
    }
    ).then(
      (response) => response.json()
    ).then(
      (json) => this.setState({output: this.state.output.slice().concat([json['output']]), bindings: json['bindings']})
    )
    this.setState({output: this.state.output.slice().concat([this.state.inputValue]), inputValue: ""})
  }

  // componentDidUpdate() {
  //   this.scrollToBottom();
  // }

  onChangeInput(e) {
    this.setState({inputValue: e.target.value})
  }

  render() {
    return <TerminalView
      history={this.state.history}
      output={this.state.output}
      onEnter={this.onEnter.bind(this)}
      inputValue={this.state.inputValue}
      onChangeInput={this.onChangeInput.bind(this)}
    />
  }
}

const TerminalView = ({history, output, inputValue, onEnter, onChangeInput}) => <label htmlFor="input" style={{height: "100%"}}>
  <div style={{}}>
    { output.slice(-34).map((output, key) => <p key={key}>{ output } </p>) }
    <form onSubmit={onEnter}>
      <input id="input" type="text" value={inputValue} onChange={onChangeInput}/>
    </form>
  </div>
</label>
