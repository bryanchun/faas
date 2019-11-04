import os
from urllib.parse import parse_qs

def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """
    # v1: plain string html
    # html = '<html><h2>Hi, from your function!</h2></html>'

    # v2: load from hard-coded html file
    # dirname = os.path.dirname(__file__)
    # path = os.path.join(dirname, 'html', 'new.html')

    # v3: load all html in the folder as per request url (dynamically)
    # | Query the last route ('new', 'list') to grab the corresponding html
    # path = os.environ['Http_Path']
    # pathArr = path.split("/")
    # pageName = pathArr[1]
    #
    # dirname = os.path.dirname(__file__)
    # path = os.path.join(dirname, 'html', pageName + '.html')

    # v4: load by query strings
    # | Still grab corresponding html file
    query = os.environ['Http_Query']
    params = parse_qs(query)
    action = params['action'][0]

    dirname = os.path.dirname(__file__)
    path = os.path.join(dirname, 'html', action + '.html')

    with open(path, 'r') as file:
        html = file.read()
    
    return html
