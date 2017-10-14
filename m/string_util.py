def ascii_only(str_input):
    return str_input.encode('ascii', errors='ignore').decode().lower()
