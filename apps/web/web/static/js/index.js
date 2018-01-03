import React from 'react'
import ReactDOM from 'react-dom'
import { Layout } from './components/Layout.jsx'

let react_root = document.getElementById('react-root')

if(react_root) {
  ReactDOM.render(<Layout />, react_root)
}
