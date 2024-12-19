#!/usr/bin/env python3
from gnuradio import gr
from gnuradio import blocks
from gnuradio import audio
import os

class wav_to_fd(gr.top_block):
    def __init__(self, wav_file, fd):
        gr.top_block.__init__(self, "WAV to File Descriptor")

        # Variables
        self.samp_rate = 44100

        # Blocks
        self.wav_source = blocks.wavfile_source(
            wav_file,
            False
        )
        self.samp_rate = self.wav_source.sample_rate()

        # Add throttle to prevent CPU overwhelming
        self.throttle = blocks.throttle(gr.sizeof_float, self.samp_rate)

        # Convert to mono
        self.mono = blocks.multiply_const_ff(0.5)

        # Add a debug probe
        self.probe = blocks.probe_rate(gr.sizeof_float)

        # Convert float to complex
        self.float_to_complex = blocks.float_to_complex()

        # File descriptor sink
        self.fd_sink = blocks.file_descriptor_sink(
            gr.sizeof_gr_complex,
            fd
        )

        # Connections
        self.connect(self.wav_source, self.throttle)
        self.connect(self.throttle, self.mono)
        self.connect(self.mono, self.probe)  # Add probe in the chain
        self.connect(self.mono, self.float_to_complex)
        self.connect(self.float_to_complex, self.fd_sink)

def create_fake_fd(file_path, mode="wb"):  # Changed to binary mode
    file = open(file_path, mode)
    fd = file.fileno()
    print(f"Fake FD created: {fd}")
    return file, fd

def main():
    import sys
    import time

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <wav_file>")
        sys.exit(1)

    wav_file = sys.argv[1]
    file_path = "fake_fd_test.bin"  # Changed to .bin extension

    # Create a fake FD
    file, fd = create_fake_fd(file_path)

    if not os.path.exists(wav_file):
        print(f"Error: WAV file '{wav_file}' does not exist")
        sys.exit(1)

    try:
        os.fstat(fd)
    except OSError:
        print(f"Error: Invalid file descriptor {fd}")
        sys.exit(1)

    # Create and run the flowgraph
    tb = wav_to_fd(wav_file, fd)
    print(f"Starting flowgraph with sample rate: {tb.samp_rate}")

    tb.start()

    # Monitor the flow for a few seconds
    try:
        for _ in range(10):  # Monitor for 10 seconds
            time.sleep(1)
            rate = tb.probe.rate()
            print(f"Current processing rate: {rate:.2f} samples/second")

            # Check if we're still processing data
            if rate == 0:
                print("Processing complete or no data flow detected")
                break

    except KeyboardInterrupt:
        print("\nStopping flowgraph...")
    finally:
        tb.stop()
        tb.wait()
        file.close()

    # Verify output
    output_size = os.path.getsize(file_path)
    print(f"\nOutput file size: {output_size} bytes")

if __name__ == '__main__':
    main()
