import imaplib
import configparser
import os
import pprint

verboseLogging = False

def open_connection():
    # Read the config file
    config = configparser.ConfigParser()
    config.read([os.path.expanduser('config.ini')])

    # Connect to the server
    hostname = config.get('server', 'hostname')
    if verboseLogging: print('Connecting to', hostname)
    connection = imaplib.IMAP4_SSL(hostname)

    # Login to our account
    username = config.get('account', 'username')
    password = config.get('account', 'password')
    if verboseLogging: print('Logging in as', username)
    connection.login(username, password)
    return connection

def dump_folders(c):
    typ, data = c.list()
    if verboseLogging: print('Response code:', typ)
    pprint.pprint(data)

def dump_folder(c, folderName):
    c.select(mailbox=folderName, readonly=True)
    messages = c.fetch('1:*', '(UID INTERNALDATE FLAGS)')
    pprint.pprint(messages)

if __name__ == '__main__':
    c = open_connection()
    try:
        print(c)
        dump_folder(c, 'INBOX')
    finally:
        c.logout()
