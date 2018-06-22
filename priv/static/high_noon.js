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

const container = document.querySelector('.container')
const player1Div = document.querySelector('.player_1')
const player1Status = document.querySelector('.player_1_status')
const player1Name = document.querySelector('.player_1_name')
const player1Assignment = document.querySelector('.player_1_assignment')
const player2Div = document.querySelector('.player_2')
const player2Status = document.querySelector('.player_2_status')
const player2Name = document.querySelector('.player_2_name')
const player2Assignment = document.querySelector('.player_2_assignment')
const clock = document.querySelector('.clock')
const toaster = document.querySelector('.toaster')
const fireButton = document.querySelector('.fire')
const registerForm = document.querySelector('.register')

registerForm.addEventListener('submit', event => {
  event.preventDefault()

  registerPlayer(event.target['0'].value)

  registerForm.remove()
})

function registerPlayer(name) {
  window.playerName = name
  const socket = new WebSocket(getWebSocketURI())
  socket.onmessage = onMessage
  socket.onclose = onClose

  socket.onopen = ev => socket.send(`name:${name}`)

  document.addEventListener('click', _ => pokeWebSocket(socket))
  document.addEventListener('keydown', _ => pokeWebSocket(socket))

  container.classList.toggle('hidden')
}

function getWebSocketURI() {
  const loc = window.location
  const wsProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:'
  return `${wsProtocol}//${loc.host}/ws`
}

function pokeWebSocket(socket) {
  socket.send('poke')
}

function onMessage(msg) {
  let data
  try {
    data = JSON.parse(msg.data)
    console.log(data)
  } catch (e) {
    console.error('Failed to parse WS message')
    console.error(msg)
    return
  }

  RESPONSE_FUNCTIONS[data.type](data)
}

function onSearching(_) {
  window.startFlag = false
  window.currentPlayer = null
  resetPlayArea()
  toaster.textContent = 'Searching...'
}

function onDisconnect(_) {
  toaster.textContent =
    'Game Disconnected! Press any key to search for a new game'
}

function onOpponentLeft(_) {
  toaster.textContent =
    'Your cowardly opponent has left! Press any key to search for a new game'
}

function onJoining(_) {
  toaster.textContent = 'Joining Game...'
}

function onJoin({ game_roster }) {
  window.currentPlayer = game_roster.assignment
  if (game_roster.assignment === 'player_1') {
    player1Assignment.textContent = '☝\nYou'
  } else {
    player2Assignment.textContent = '☝\nYou'
  }
  player1Name.textContent = game_roster.player_1
  player1Status.textContent = 'is not ready'
  player2Name.textContent = game_roster.player_2
  player2Status.textContent = 'is not ready'
  toaster.textContent = 'Waiting for players to be ready'
}

function onGameUpdate({ game_readiness, game_state }) {
  if (!game_state.started) {
    player1Status.textContent = game_readiness.player_1_ready
      ? 'is ready'
      : 'is not ready'
    player2Status.textContent = game_readiness.player_2_ready
      ? 'is ready'
      : 'is not ready'

    if (game_readiness.player_1_ready && game_readiness.player_2_ready) {
      toaster.textContent =
        'Players ready! Game Starting soon\nFire when the clock reaches High Noon!'
    }
  } else {
    if (!window.startFlag) {
      window.startFlag = true
      toaster.textContent = 'The Game has Begun!'
      setTimeout(() => (toaster.textContent = ''), 2000)
    }

    if (game_state.high_noon) {
      clock.textContent = NOON
    }

    switch (game_state.player_1_status) {
      case 'fine':
        player1Status.textContent = 'is doing fine'
        break
      case 'backfired':
        player1Status.textContent =
          "is dead! Their gun backfired! Don't shoot before high noon!"
        break
      case 'shot':
        player1Status.textContent = 'got hella shot to death'
        break
    }

    switch (game_state.player_2_status) {
      case 'fine':
        player2Status.textContent = 'is doing fine'
        break
      case 'backfired':
        player2Status.textContent =
          "is dead! Their gun backfired! Don't shoot before high noon!"
        break
      case 'shot':
        player2Status.textContent = 'got hella shot to death'
        break
    }

    player1Div.textContent =
      game_state.player_1_status === 'fine' ? ALIVE_SHERIFF : DEAD_SHERIFF
    player2Div.textContent =
      game_state.player_2_status === 'fine' ? ALIVE_SHERIFF : DEAD_SHERIFF

    if (game_state.winner !== null) {
      if (game_state.winner === 'draw') {
        toaster.textContent =
          'You both lose!\nPress any key to search for a new game'
      } else if (game_state.winner === window.currentPlayer) {
        toaster.textContent = 'You win!\nPress any key to search for a new game'
      } else {
        toaster.textContent =
          'You lose!\nPress any key to search for a new game'
      }
    }
  }
}

const RESPONSE_FUNCTIONS = {
  searching: onSearching,
  disconnected: onDisconnect,
  opponent_left: onOpponentLeft,
  joining_game: onJoining,
  joined_game: onJoin,
  game_update: onGameUpdate
}

function resetPlayArea() {
  clock.textContent = ELEVEN_O_CLOCK
  player1Div.textContent = ALIVE_SHERIFF
  player2Div.textContent = ALIVE_SHERIFF
  remainingElements = [
    player1Name,
    player1Status,
    player1Assignment,
    player2Name,
    player2Status,
    player2Assignment,
    toaster
  ]
  remainingElements.forEach(element => (element.textContent = ''))
}

function onClose(msg) {
  console.log('WebSocket closed')
}
