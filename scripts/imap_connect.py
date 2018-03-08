import imaplib
import configparser
import os
import pprint
import re

verboseLogging = False

def open_connection():
    # Read the config file
    config = configparser.ConfigParser()
    config.read([os.path.expanduser('secret.ini')])

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
    print(folderName)
    c.select(mailbox=folderName, readonly=True)
    messages = c.fetch('1:*', '(UID INTERNALDATE FLAGS)')
    pprint.pprint(messages)

def rm_folders(c):
    typ, data = c.list()
    pprint.pprint(data)
    p1 = re.compile('"([^"]*)"')
    p2 = re.compile('INBOX.Folder')
    p3 = re.compile('<[a-zA-Z].*>')
    for line in data:
        m = p1.findall(str(line))
        if m != None:
            mailbox = m[1]
            if p2.match(mailbox) or p3.match(mailbox):
                print("will delete |" + mailbox + "|")
                quoted = '"' + mailbox + '"'
                r = c.delete(quoted)
                pprint.pprint(r)

if __name__ == '__main__':
    c = open_connection()
    try:
        print(c)
        dump_folder(c, 'INBOX')
    finally:
        c.logout()
