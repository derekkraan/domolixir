import React from 'react'

export const Layout = ({children}) => <div>
  <div className="header">
    Domolixir
  </div>

  <nav className="menu">
    <a href="/dashboard">Dash</a>
    <a href="/networks">Netwks</a>
  </nav>

  <div className="container">
    { children }
  </div>
</div>
