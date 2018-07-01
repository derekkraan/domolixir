import { store } from '../store'

export const refreshNetworks = () => {
  fetch('/networks').then((response) => {
    response.json().then((json) => {
      store.dispatch({type: "UPDATE_NETWORKS", networks: json})
    })
  })
}
