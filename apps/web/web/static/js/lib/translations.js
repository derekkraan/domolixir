export const t = (word, options = {}) => {
  if(Object.prototype.hasOwnProperty.call(translations_en, word)) {
    return translations_en[word]
  }
  return `Unknown translation: ${word}`
}

const translations_en = {
  'command.basic_set': 'Set (Base functionality)',
  'command.basic_get': 'Get (Base functionality)',
  'command.turn_on': 'Turn On',
  'command.turn_off': 'Turn Off',
  'command.set_brightness': 'Set Brightness',
  'command.wakeup_get_interval': 'Get Wakeup Interval',
  'command.association_set': 'Set Association',
  'command.association_groupings_get': 'Get Association Groupings',
  'command.switch_multilevel_set': 'Set Level',
  'command.switch_multilevel_get': 'Get Level',
  'command.switch_multilevel_supported_get': 'Get Supported Levels',
  'field.brightness': 'Brightness',
}
