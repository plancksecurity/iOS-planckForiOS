#
# Functions for reading IMAP connect info from ini files
#

import imaplib
import configparser

# Reads the section of the given name
def ini_section(ini, account_name):
    config = configparser.ConfigParser()
    config.read(ini)
    return config[account_name]

# Creates an IMAP connection to the given account_name in the given
# INI-file.
def connect_account(ini, account_name):
    data = ini_section(ini, account_name)
    hostname = data.get('hostname')
    username = data.get('username')
    password = data.get('password')
    port = data.get('port') or 993
    print('connecting to host: {}, port: {}'.format(hostname, port))
    tls = data.get('tls') or 'yes'
    con = None
    theTls = tls.lower()
    if theTls == 'yes' or theTls == 'true':
        con = imaplib.IMAP4_SSL(hostname, port=port)
    else:
        con = imaplib.IMAP4(hostname, port=port)
    con.login(username, password)
    return con
