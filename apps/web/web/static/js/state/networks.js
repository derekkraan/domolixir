let initial_networks = []

export const networks = (state = initial_networks, action) => {
  switch(action.type) {
    case "UPDATE_NETWORKS":
      return action.networks
  }
  return state
}
