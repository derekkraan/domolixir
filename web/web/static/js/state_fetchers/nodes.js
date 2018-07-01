import { store } from '../store'

export const refreshNodes = () => {
  fetch('/nodes').then((response) => {
    response.json().then((json) => {
      store.dispatch({type: "UPDATE_NODES", nodes: json})
    })
  })
}
