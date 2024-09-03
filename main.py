from pygit2 import Repository

repo = Repository('.')

all_obj = list(repo)
repo[all_obj[1]] # pobiera obiekt

print(repo)