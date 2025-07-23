const FERMO_LIVE_SOCKET = (location => {
  console.debug('fermo-live: initializing WebSocket connection, location: ', location)

  const PING_INTERVAL = 10000 // 10 seconds

  const protocol = location.protocol == 'https:' ? 'wss' : 'ws'
  const socketPath = `${protocol}://${location.host}/__fermo/ws/live-reload`
  const socket = new window.WebSocket(socketPath)
  let pingTimer = null

  const reloadPage = () => {
    window.location.reload()
  }

  socket.onopen = e => {
    console.debug('fermo-live: socket onopen')
    socket.send('subscribe:live-reload:' + window.location.pathname)

    pingTimer = window.setInterval(() => {
      socket.send(JSON.stringify({event: 'ping'}))
    }, PING_INTERVAL)
  }

  socket.onmessage = (event) => {
    console.debug('fermo-live: onmessage: ', event)
    if (event.data === 'reload') {
      reloadPage()
    }
  }

  socket.onclose = event => {
    if(pingTimer) {
      window.clearInterval(pingTimer)
      pingTimer = null
    }

    if (event.wasClean) {
      console.debug('fermo-live: onclose clean event:', event)
    } else {
      // TODO: Poll to try to reconnect
      console.debug('fermo-live: onclose non-clean event:', event)
    }
  }

  socket.onerror = error => {
    console.error('fermo-live: onerror error:', error)
  }

  return socket
})(window.location)
