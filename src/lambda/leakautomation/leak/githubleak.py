from github import Github
from github import Auth

from dotenv import load_dotenv
import os

class Githubleak:
    def __init__(self, repo_name, template, event):
        self.repo_name = repo_name
        self.template = template
        self.event = event
    
    def _get_template_files(self, root):
        all_files = []

        for path, subdirs, files in os.walk(root):
            for name in files:
                all_files.append(os.path.join(path, name).replace("\\", "/").replace(root, ""))

        return(all_files)

    def _replace_keyvalues(self, file_content, keyvalues):
        for keyvalue in keyvalues:
            file_content = file_content.replace("${}$".format(keyvalue.get("key")), format(keyvalue.get("value")))
        
        return file_content

    def leak(self):
        load_dotenv()

        github_secret = os.getenv("GITHUB_SECRET")
        auth = Auth.Token(github_secret)
        g = Github(auth=auth)

        organization = g.get_organization("CasperLake")

        organization.create_repo(self.repo_name, private=False)

        repo = organization.get_repo(self.repo_name)

        for file in self._get_template_files("template/{}/".format(self.template)):
            repo.create_file(file, "committing files", self._replace_keyvalues(open("template/{}/{}".format(self.template, file), 'r').read(), self.event), branch="master")
        
    def clean(self):
        load_dotenv()
        
        github_secret = os.getenv("GITHUB_SECRET")

        auth = Auth.Token(github_secret)

        g = Github(auth=auth)

        organization = g.get_organization("LeakOrganization")

        repo_name = self.repo_name

        repo = organization.get_repo(repo_name)
        repo.delete()