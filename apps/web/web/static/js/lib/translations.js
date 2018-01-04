export const t = (word, options = {}) => {
  if(Object.prototype.hasOwnProperty.call(translations_en, word)) {
    return translations_en[word]
  }
  return `Unknown translation: ${word}`
}

const translations_en = {
  'command.turn_on': 'Turn On',
  'command.turn_off': 'Turn Off',
  'command.set_brightness': 'Set',
  'field.brightness': 'Brightness',
}
