const words = ['apple', 'banana', 'cat', 'dog', 'elephant', 'fox', 'grape', 'hippo', 'igloo', 'james', 'kangaroo', 'lion', 'monkey', 'nest', 'octopus', 'penguin', 'quokka', 'rabbit', 'snake', 'tiger', 'umbrella', 'vulture', 'whale', 'xylophone', 'yak', 'zebra']

const generateRandomWords = () => {
    return `${words[Math.floor(Math.random() * words.length)]}.${words[Math.floor(Math.random() * words.length)]}.${words[Math.floor(Math.random() * words.length)]}`
}

module.exports = { generateRandomWords }