const ALIVE_SHERIFF = `     　 　 🤠
　 　 😀😀😀
　 😀　 😀　 😀
👇　 😀　 😀　 👇
　 　 😀　 😀
　 　 😀　 😀
　 　 👢　 👢`

const DEAD_SHERIFF = `     　 　 🤠
　 　 💀💀💀
　 💀　 💀　 💀
👇　 💀　 💀　 👇
　 　 💀　 💀
　 　 💀　 💀
　 　 👢　 👢`

const ELEVEN_O_CLOCK = '🕚'
const NOON = '🕛'

const player1Div = document.querySelector('.player1')
const player2Div = document.querySelector('.player2')
const registerForm = document.querySelector('.register')

registerForm.addEventListener('submit', event => {
  event.preventDefault()

  registerPlayer(event.target['0'].value)

  registerForm.remove()
})

player1Div.textContent = ALIVE_SHERIFF
player2Div.textContent = DEAD_SHERIFF

function registerPlayer(name) {
  window.playerName = name
  const socket = new WebSocket(getWebSocketURI())
  socket.onmessage = onMessage
  socket.onclose = onClose

  socket.onopen = ev => socket.send(`name:${name}`)
}

function getWebSocketURI() {
  const loc = window.location
  const wsProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:'
  return `${wsProtocol}//${loc.host}/ws`
}

function onMessage(msg) {
  let data
  try {
    data = JSON.parse(msg.data)
  } catch (e) {
    data = msg.data
  }

  console.log(data)
}

function onClose(msg) {}
