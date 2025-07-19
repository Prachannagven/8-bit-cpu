def hexdump(filepath):
    try:
        with open(filepath, "rb") as f:
            offset = 0
            while True:
                chunk = f.read(16)
                if not chunk:
                    break

                # Hexadecimal representation
                hex_bytes = ' '.join(f'{b:02X}' for b in chunk)
                hex_bytes = hex_bytes.ljust(47)  # pad to 16 bytes * 3 - 1

                # ASCII representation
                ascii_repr = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in chunk)

                # Print line
                print(f'{offset:08X}  {hex_bytes}  |{ascii_repr}|')
                offset += len(chunk)
    except FileNotFoundError:
        print(f"File '{filepath}' not found.")


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python hexdump_emulator.py <filename>")
    else:
        hexdump(sys.argv[1])
