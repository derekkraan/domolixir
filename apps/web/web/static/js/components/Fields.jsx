import React from 'react'

export const Field = (props) => {
  let Elem = fieldElement(props.field)
  return <Elem {...props} />
}

const fieldElement = (field) => {
  switch(field[1]) {
    case "float": return FloatField
    case "float_0_1": return FloatField
  }
  return UnknownField
}

const UnknownField = (props) => <p>
  Unknown field `{ props.field[1] }`
</p>

const FloatField = ({field, onChange, value}) => <p>
  {field[0]}
  <input onChange={(e) => onChange(e.target.value)} value={value} />
</p>
