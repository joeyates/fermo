class FermoLiveSocket {
  PING_INTERVAL = 10000 // 10 seconds

  constructor(location) {
    this.location = location
    this.pingTimer = null
    this.initializeWebSocket()
  }

  rebuild() {
    console.debug(`fermo-live: rebuild:${this.location.pathname}`)
    this.socket.send('rebuild:' + this.location.pathname)
  }

  reloadPage() {
    this.location.reload()
  }

  // Below are private methods

  initializeWebSocket() {
    this.socket = new window.WebSocket(this.socketPath)

    this.socket.onopen = e => {
      console.debug('fermo-live: socket onopen')
      this.subscribe()
      this.startPing()
    }

    this.socket.onmessage = (event) => {
      console.debug('fermo-live: onmessage: ', event)
      if (event.data === 'reload') {
        this.reloadPage()
      }
    }

    this.socket.onclose = event => {
      this.clearPingTimer()

      if (event.wasClean) {
        console.debug('fermo-live: onclose clean event:', event)
      } else {
        // TODO: Poll to try to reconnect
        console.debug('fermo-live: onclose non-clean event:', event)
      }
    }

    this.socket.onerror = error => {
      console.error('fermo-live: onerror error:', error)
    }
  }

  subscribe() {
    console.debug('fermo-live: subscribe:live-reload:', this.location.pathname)
    this.socket.send('subscribe:live-reload:' + this.location.pathname)
  }

  startPing() {
    this.clearPingTimer()
    this.pingTimer = window.setInterval(() => {
      this.socket.send(JSON.stringify({event: 'ping'}))
    }, this.PING_INTERVAL)
  }

  clearPingTimer() {
    if (this.pingTimer) {
      window.clearInterval(this.pingTimer)
      this.pingTimer = null
    }
  }

  // Define property getter for socketPath
  get socketPath() {
    const protocol = this.location.protocol === 'https:' ? 'wss' : 'ws'
    return `${protocol}://${this.location.host}/__fermo/ws/live-reload`
  }
}

window.fermoLiveSocket = new FermoLiveSocket(window.location)
