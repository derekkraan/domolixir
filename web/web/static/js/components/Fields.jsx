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

export class OnOffSlider extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      slider_offset: null,
      value: props.value,
    }
  }

  dragHandler (e) {
    e.preventDefault()
    this.setState({slider_offset: Math.max(0, Math.min(40, e.clientX - e.currentTarget.getBoundingClientRect().x - 18.5))})
  }

  dropHandler (e) {
    e.preventDefault()
    console.log('dropped!')
    this.setState({slider_offset: null})
    this.onChange(this.state.slider_offset > 20)
  }

  sliderOffset () {
    if(this.state.slider_offset) { return this.state.slider_offset }
    return this.state.value ? '40px' : '0'
  }

  sliderStyle () {
    return {
      left: this.sliderOffset(),
      transition: this.state.slider_offset ? '' : 'left 0.1s',
    }
  }

  componentWillReceiveProps (nextProps) {
    console.log('nextProps!!', nextProps)
    this.setState({value: nextProps.value})
  }

  onChange (value) {
    this.setState({value: value})
    this.props.onChange(value)
  }

  render () {
    if(this.props.trackThisOne) {
      console.log(this.sliderStyle())
    }
    return <OnOffSliderView {...this.props} {...this.state} onChange={this.onChange.bind(this)} slider_style={this.sliderStyle()} dragHandler={this.dragHandler.bind(this)} dropHandler={this.dropHandler.bind(this)} />
  }
}

export const OnOffSliderView = ({field, onChange, value, slider_style, dragHandler, dropHandler}) => <div onClick={(e) => {onChange(value ? false : true)}} className={`on_off_slider ${value ? 'on' : 'off'}`} onDragOver={dragHandler} onDrop={dropHandler}>
  <div className="slider_part" style={slider_style}>
    <div className="on_off_circle">
      <div className="draggable_part" draggable={true} />
    </div>
  </div>
</div>
