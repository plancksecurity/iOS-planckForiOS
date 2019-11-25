#
# Functions for reading IMAP connect info from ini files
#

import imaplib
import configparser
from pprint import pformat, pprint


def ini_section(ini, account_name):
    """Reads the section of the given name"""
    config = configparser.ConfigParser()
    config.read(ini)
    return config[account_name]

def connect_account(ini, account_name):
    """Creates an IMAP connection to the given account_name in the given INI file"""
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

    print("Capabilities returned on connect: %s" % pformat(con.capabilities))

    capabilites = "None"
    (status, data) = con.capability()
    if status == "OK":
        capabilites = data[0].decode()

    print("Capabilities returned on CAPABILITY: %s" % pformat(capabilites))

    return con
