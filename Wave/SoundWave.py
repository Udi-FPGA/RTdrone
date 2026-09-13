import socket
import numpy as np
import sounddevice as sd

# Configuration
UDP_PORT = 1234
SAMPLE_RATE = 8000 # Adjust if it sounds too fast/slow

# Setup Socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("", UDP_PORT))
sock.settimeout(0.1)

# Open Audio Stream (16-bit signed, Mono)
# We force dtype to 'int16' here
stream = sd.OutputStream(samplerate=SAMPLE_RATE, channels=1, dtype='int16')
stream.start()

print("Listening for MSB-First Drone Wave...")

try:
    while True:
        try:
            data, addr = sock.recvfrom(4096)
            
            # 1. Convert to numpy uint8
            raw_bytes = np.frombuffer(data, dtype=np.uint8)
            
            # 2. Ensure we have pairs (High, Low)
            if len(raw_bytes) % 2 != 0:
                raw_bytes = raw_bytes[:-1]
                
            # 3. Interpret as Big-Endian ('>') 16-bit signed integer ('i2')
            # This directly handles the MSB-first ordering (High Byte, Low Byte)
            audio_samples = raw_bytes.view(dtype='>i2')
            
            # 4. Force a copy to standard int16 to fix the dtype mismatch error
            audio_samples = audio_samples.astype(np.int16)

            # Multiply by a gain factor (e.g., 50x)
            # Make sure to clip it so it doesn't distort (wrap around)
            audio_samples = np.clip(audio_samples * 64, -32768, 32767).astype(np.int16)
            
            # Convert to 'int32' just for the print statement to avoid the int16 bounds error
            print_samples = audio_samples[:5].astype(np.int32)
            print(f"Sample Hex: {[f'{x & 0xFFFF:04X}' for x in print_samples]}")  
          
            # 5. Play
            stream.write(audio_samples)
            
        except socket.timeout:
            continue

except KeyboardInterrupt:
    print("\nStopping...")
    stream.stop()
    stream.close()
    sock.close()