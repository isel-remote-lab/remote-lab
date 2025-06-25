import asyncio
import string
import websockets
import os
import pty
import subprocess
import fcntl
import termios
import json
import sys
import requests

class PTYServer:
    def __init__(self):
        self.master_fd = None
        self.slave_fd = None
        self.shell = None
        self.clients = set()
        
    def setup_pty(self):
        # Create a master/slave pseudo-terminal pair
        self.master_fd, self.slave_fd = pty.openpty()
        
        # Set non-blocking mode on the master_fd. Needed for the emulator terminal.
        flags = fcntl.fcntl(self.master_fd, fcntl.F_GETFL)
        fcntl.fcntl(self.master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)
        
        # Start shell on slave side of PTY
        env = os.environ.copy()
        
        self.shell = subprocess.Popen(
            ["/bin/bash", "-i"],  # Interactive bash
            preexec_fn=os.setsid,
            stdin=self.slave_fd,
            stdout=self.slave_fd,
            stderr=self.slave_fd,
            env=env,
            bufsize=0,
            close_fds=True
        )
        
        # Close slave_fd in parent process
        os.close(self.slave_fd)
        
    def set_winsize(self, rows, cols):
        if self.master_fd:
            import struct
            size = struct.pack("HHHH", rows, cols, 0, 0)
            fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, size)
    
    async def read_from_pty(self, websocket):
        """Read from PTY and send to WebSocket clients"""
        loop = asyncio.get_running_loop()
        
        while websocket in self.clients:
            try:
                # Use a small timeout to prevent blocking
                output = await asyncio.wait_for(
                    loop.run_in_executor(None, self._read_pty_data), 
                    timeout=0.1
                )
                
                if output:
                    message = {
                        "type": "output",
                        "data": output
                    }
                    if websocket in self.clients:
                        await websocket.send(json.dumps(message))
                        
            except asyncio.TimeoutError:
                # No data available, continue
                continue
            except (OSError, websockets.exceptions.ConnectionClosed):
                break
            except Exception as e:
                print(f"Error reading from PTY: {e}")
                break
    
    def _read_pty_data(self):
        """Blocking read from PTY - runs in executor"""
        try:
            return os.read(self.master_fd, 1024).decode(errors="replace")
        except (OSError, BlockingIOError):
            return None
    
    async def write_to_pty(self, websocket):
        """Receive from WebSocket and write to PTY"""
        async for message in websocket:
            try:
                data = json.loads(message)
                
                if data.get("type") == "input":
                    input_data = data["data"]
                    os.write(self.master_fd, input_data.encode())
                    
                elif data.get("type") == "resize":
                    cols = data.get("cols", 80)
                    rows = data.get("rows", 24)
                    self.set_winsize(rows, cols)
                    
            except json.JSONDecodeError:
                # Fallback: treat as raw input
                os.write(self.master_fd, message.encode())
            except (OSError, websockets.exceptions.ConnectionClosed):
                break
            except Exception as e:
                print(f"Error writing to PTY: {e}")
                break
    
    async def handle_client(self, websocket):
        """Handle a WebSocket client connection"""
        print(f"Client connected: {websocket.remote_address}")
        self.clients.add(websocket)
        
        try:
            # Send initial prompt
            await websocket.send(json.dumps({
                "type": "output", 
                "data": f"Connected to PTY server\r\n"
            }))
            
            # Start concurrent tasks for reading and writing
            await asyncio.gather(
                self.read_from_pty(websocket),
                self.write_to_pty(websocket)
            )
            
        except websockets.exceptions.ConnectionClosed:
            print(f"Client disconnected: {websocket.remote_address}")
        except Exception as e:
            print(f"Error handling client: {e}")
        finally:
            self.clients.discard(websocket)
    
    def cleanup(self):
        """Clean up resources"""
        if self.shell:
            self.shell.terminate()
            try:
                self.shell.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.shell.kill()
        
        if self.master_fd:
            os.close(self.master_fd)

async def main():
    if sys.argv.__len__() < 3:
        print("Invalid arguments")
        sys.exit()

    hardware_name = str(sys.argv[1])
    serial_number = str(sys.argv[2])
    initial_state = "A" # Available
    port = str(sys.argv[3])
    address = str(sys.argv[4]) if sys.argv.__len__() > 4 else "localhost"
    ip_address = address + ":" + port
    

    data = {
        "name": hardware_name,
        "serialNumber": serial_number,
        "status": initial_state,
        "ipAddress": ip_address
    }

    res = requests.post(url = "http://localhost:8080/api/v1/hardware", json = data, headers={"X-API-Key": os.environ.get("API_KEY")})
    response = json.loads(res.text)
    print(response)

    server = PTYServer()
    server.setup_pty()
    
    try:
        async with websockets.serve(server.handle_client, "localhost", int(port)):
            print("WebSocket PTY server started on ws://localhost:6060")
            print("Press Ctrl+C to stop the server")
            await asyncio.Future()  # Run forever
            
    except KeyboardInterrupt:
        print("\nShutting down server...")
    finally:
        server.cleanup()

if __name__ == "__main__":
    asyncio.run(main())