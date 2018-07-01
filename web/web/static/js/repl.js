import React from 'react'
import ReactDOM from 'react-dom'
import { Terminal } from './components/Terminal.jsx'

let terminal = document.getElementById('terminal')

if(terminal) {
  ReactDOM.render(<Terminal />, terminal)
}
