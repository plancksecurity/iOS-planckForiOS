import imaplib
import argparse

def imap_connect(hostname):
    connection = imaplib.IMAP4_SSL(hostname)
    return connection

def imap_move_dummy(connection):
    return connection.uid("move", 1, "new_folder")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('hostname')
    args = parser.parse_args()
    c = imap_connect(args.hostname)
    try:
        print(c.capabilities)
    finally:
        c.logout()
