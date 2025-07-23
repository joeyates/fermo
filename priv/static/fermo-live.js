const FERMO_LIVE_SOCKET = (location => {
  const PING_INTERVAL = 10000 // 10 seconds

  const protocol = location.protocol == 'https:' ? 'wss' : 'ws'
  const socketPath = `${protocol}://${location.host}/__fermo/ws/live-reload`
  const socket = new window.WebSocket(socketPath)
  let pingTimer = null

  const reloadPage = () => {
    window.location.reload()
  }

  socket.onopen = e => {
    console.log('socket onopen')
    socket.send('subscribe:live-reload:' + window.location.pathname)
    pingTimer = window.setInterval(() => {
      socket.send(JSON.stringify({event: 'ping'}))
    }, PING_INTERVAL)
  }

  socket.onmessage = (event) => {
    console.log('onmessage: ', event)
    if (event.data === 'reload') {
      reloadPage()
    }
  }

  socket.onclose = event => {
    // Clean up ping timer
    if(pingTimer) {
      window.clearInterval(pingTimer)
      pingTimer = null
    }
    if (event.wasClean) {
      console.log('onclose clean event:', event)
    } else {
      // TODO: Poll to try to reconnect
      console.log('onclose died event:', event)
    }
  }

  socket.onerror = error => {
    console.log('onerror error:', error)
  }

  return socket
})(window.location)
