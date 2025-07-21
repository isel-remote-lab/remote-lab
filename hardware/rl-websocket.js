const WebSocket = require('ws')
const os = require('os')
const pty = require('node-pty')
const { spawn } = require('child_process')

const wss = new WebSocket.Server({ port: 1906 })

console.log('WebSocket server started on port 1906')

const allowedOrigins = ['http://localhost'];

wss.on('connection', (ws, _) => {
  console.log('Client connected')

  // 1. Run fastfetch and send its output to the client
  const fastfetch = spawn('fastfetch')
  let fastfetchOutput = ''

  fastfetch.stdout.on('data', (data) => {
    fastfetchOutput += data.toString()
  })

  fastfetch.stderr.on('data', (data) => {
    fastfetchOutput += data.toString()
  })

  fastfetch.on('close', (code) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'output',
        data: fastfetchOutput
      }))
    }

    // 2. Spawn shell process after fastfetch output
    const shell = os.platform() === 'win32' ? 'powershell.exe' : 'bash'
    const ptyProcess = pty.spawn(shell, [], {
      name: 'xterm-color',
      cols: 80,
      rows: 24,
      cwd: process.env.HOME,
      env: process.env
    })

    // Send shell output to client
    ptyProcess.onData((data) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'output',
          data: data
        }))
      }
    })

    // Handle messages from client
    ws.on('message', (message) => {
      try {
        const parsed = JSON.parse(message)

        if (parsed.type === 'input') {
          ptyProcess.write(parsed.data)
        } else if (parsed.type === 'resize') {
          ptyProcess.resize(parsed.cols, parsed.rows)
        }
      } catch (e) {
        console.error('Error parsing message:', e)
      }
    })

    // Clean up when client disconnects
    ws.on('close', () => {
      console.log('Client disconnected')
      ptyProcess.kill()
    })

    // Handle shell process exit
    ptyProcess.onExit(() => {
      console.log('Shell process exited')
      ws.close()
    })
  })
})
