let initial_nodes = []

export const nodes = (state = initial_nodes, action) => {
  switch(action.type) {
    case "UPDATE_NODES":
      return action.nodes
  }
  return state
}
