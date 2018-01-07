import React from 'react'
import { t } from '../lib/translations'

export const Field = (props) => {
  let Elem = fieldElement(props.field)
  return <Elem {...props} />
}

const fieldElement = (field) => {
  switch(field[1]) {
    case "float": return FloatField
    case "float_0_1": return FloatField
    case "integer_0_100": return IntegerField
  }
  return UnknownField
}

const UnknownField = (props) => <label>
  Unknown field `{ props.field[1] }`
</label>

const FloatField = ({field, onChange, value}) => <label>
  { t(`field.${field[0]}`) }
  <input onChange={(e) => onChange(e.target.value)} value={value} />
</label>

const IntegerField = ({field, onChange, value}) => <label>
  { t(`field.${field[0]}`) }
  <input onChange={(e) => onChange(e.target.value)} value={value} />
</label>

export const OnOffSlider = ({field, onChange, value}) => <div onClick={(e) => {onChange(value ? false : true)}} className={`on_off_slider ${value ? 'on' : 'off'}`}>
  <div className="slider_part">
    <div className="on_off_circle" />
  </div>
</div>
