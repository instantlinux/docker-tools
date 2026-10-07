#!/usr/bin/env python3
"""
updater.py

  created 2-oct-2026 by richb@instantlinux.net

  Compares JSON output of current_inventory with find_latest to
  generate a change set for dependency updates.

Options:
  --current FILE      current version dependencies  [default: -/lib/build/inventory.json]
  --latest FILE       latest-available dependencies [default: latest.json]
  -i, --ignore FILE   dependencies to skip over     [default: -/lib/build/updater/ignore.json]
  -o, --out FILE      save change set as FILE       [default: /dev/tty]
  -n, --no-out        suppress changeset output
  -f, --format FMT    output format json md yaml    [default: json]
  -d, --destpath DIR  git destination               [default: /tmp/gitrepo]
  -s, --scripts DIR   location of scripts           [default: -/lib/build/updater]
  --clone REPO        clone repo                    [default: git@github.com:instantlinux/docker-tools.git]
  -u, --update        apply updates unless dry-run
  --pr                generate a pull request
  --pr-title PAT      title for PR                  [default: Dependency updates for %d-%b-%Y]
  --branch PAT        pattern to use for branch     [default: updater/%Y%m%d-%H%M]
  --dry-run           show list of updates only

Default pathnames are relative to current directory unless destpath is activated
by update.
"""  # noqa

import copy
from datetime import datetime
import git
from github import Auth as GitAuth
from github import Github
import jinja2
import json
import os
from packaging.version import parse as version_parse
from packaging.version import InvalidVersion
import re
import subprocess
import sys
import yaml
import yadopt

# List of versions mentioned in top-level README
readme_doc = ['apache', 'grafana', 'headscale', 'jira', 'nexus',
              'radicale', 'splunk', 'synapse']
# Markdown format for jinja2
changes_md = (
    "| Category | Item | Current | New |\n"
    "| --- | --- | --- | --- |\n"
    "{% set ns = namespace(prev_cat='') %}"
    "{% for category, row in dependencies.items() -%}\n"
    "{% for item, val in row.items() -%}\n"
    "| {% if category != ns.prev_cat %}{{ category }}{% endif %} |"
    " {{ item }} | {{ val.version }} | {{ val.available }} |\n"
    "{% set ns.prev_cat = category %}"
    "{% endfor %}{% endfor %}")
md_template = jinja2.Template(changes_md)
pr_template = jinja2.Template(
    "## Summary of Changes\n"
    "This updates the following dependencies:\n\n%s"
    "## Why is this change being made?\n"
    "Routine dependency updates identified by lib/build/updater tool\n\n"
    "## How was this tested? How can the reviewer verify your testing?\n"
    "CI pipeline\n\n"
    "## Completion checklist\n"
    "- [x] Documentation has been updated\n"
    "- [ ] Dependencies have been updated and verified\n" % changes_md
)


def edit_file(dir, filename, old_ver, new_ver):
    full_path = os.path.join(dir, filename)
    with open(full_path, 'r') as file:
        contents = file.read()
    # TODO - refine this to prevent false matches
    contents = contents.replace(old_ver, new_ver)
    with open(full_path, 'w') as file:
        file.write(contents)


def get_changeset(inventory, latest, ignore):
    with open(inventory, 'r', encoding='utf-8') as file:
        current = json.load(file)
    # Remove any ignored items from the changeset
    changeset = copy.deepcopy(current)
    for category in latest:
        if category == 'manual-checks':
            continue
        for item in current[category]:
            if ignore and category in ignore and item in ignore[category]:
                del changeset[category][item]
                continue
            if item not in latest[category]:
                continue
            if latest[category][item]['version'] == current[
                    category][item]['version']:
                del changeset[category][item]
            else:
                changeset[category][item]['available'] = latest[
                    category][item]['version']
    return changeset


def output_changeset(output_file, fmt, changeset):
    with open(output_file, 'w') as file:
        if fmt == 'json':
            file.write(json.dumps(changeset, indent=2))
        elif fmt == 'yaml':
            file.write(yaml.safe_dump(changeset))
        elif fmt == 'md':
            file.write(md_template.render(dependencies=changeset))
        else:
            raise ValueError("Usage: format must be json / md / yaml")


def process_updates(changeset, destpath, repo, branch, dry_run):
    if not dry_run:
        repo.create_head(branch).checkout()
    changes = 0
    skip = []
    for category in changeset:
        if category == 'manual-checks':
            continue
        for item in changeset[category]:
            if not changeset[category][item]['version']:
                print("Skipped missing version for %s in %s" % (
                    item, category))
                skip.append({'category': category, 'item': item})
                continue
            elif 'available' not in changeset[category][item]:
                print("No available version found for %s in %s" % (
                    item, category))
                skip.append({'category': category, 'item': item})
                continue
            if category == 'github-imports':
                print('ready to edit %s: %s(was %s)' % (
                    item, changeset[category][item]['available'],
                    changeset[category][item]['version']))
            try:
                available = version_parse(
                    re.sub(r'-([a-zA-Z0-9]+)$', r'+\1',
                           changeset[category][item]['available']))
                current = version_parse(
                    re.sub(r'-([a-zA-Z0-9]+)$', r'+\1',
                           changeset[category][item]['version']))
                newer = available > current
            except InvalidVersion:
                # Some third-party packages have non-PEP 440 versions,
                # here we simply assume the available version is new
                newer = True
            if newer:
                if category == 'github-imports':
                    print("doing files: %s" % changeset[category][item]['paths'])
                for file in changeset[category][item]['paths']:
                    if dry_run:
                        print(file)
                    else:
                        edit_file(destpath, file,
                                  changeset[category][item]['version'],
                                  changeset[category][item]['available'])
                # For listed charts: make an extra edit to README
                if (not dry_run and category == 'charts' and
                        item in readme_doc):
                    edit_file(destpath, 'README.md',
                              changeset[category][item]['version'],
                              changeset[category][item]['available'])
                changes += 1
            else:
                print("Skipped older version %s found for %s(%s) in %s" % (
                    changeset[category][item]['available'], item,
                    changeset[category][item]['version'], category))
                skip.append({'category': category, 'item': item})
    for obj in skip:
        del changeset[obj['category']][obj['item']]
    return changes


def update_inventory(scripts_path, dest_path):
    scripts_path = re.sub(r"^-", dest_path, scripts_path)
    result = subprocess.run([os.path.join(scripts_path,
                                          'current_inventory.sh')],
                            env={'REPO_PATH': dest_path},
                            capture_output=True, text=True)
    with open(os.path.join(dest_path, 'lib/build/inventory.json'),
              'w', encoding='utf-8') as file:
        file.write(result.stdout)
    with open(os.path.join(dest_path, 'lib/build/inventory.md'),
              'w', encoding='utf-8') as file:
        file.write(md_template.render(dependencies=json.loads(result.stdout)))
    git.Repo(dest_path).index.add(['lib/build/inventory.json',
                                   'lib/build/inventory.md'])


def generate_pr(changeset, repo, gh_reponame, title, body, branch, base):
    del changeset['manual-checks']
    repo.git.commit('-a', '-S', m=title)
    repo.git.push("--set-upstream", "origin", repo.head.ref)
    auth = GitAuth.Token(os.environ["GITHUB_TOKEN"])
    gh_repo = Github(auth=auth).get_repo(gh_reponame)
    try:
        pr = gh_repo.create_pull(title=title, body=body, head=branch,
                                 base=base)
        pr.add_to_labels("dependencies")
        return pr.html_url
    except Exception as e:
        print(f"PR generation failed: {e}")
        sys.exit(1)


def main():
    sys.tracebacklimit = 0
    args = yadopt.parse(__doc__)

    if args.update:
        try:
            os.mkdir(args.destpath)
        except FileExistsError:
            print(f"Please remove directory {args.destpath} to proceed",
                  file=sys.stderr)
            sys.exit(1)
        repo = git.Repo.clone_from(args.clone, args.destpath, depth=1)
        location = args.destpath
    else:
        location = '.'

    with open(args.latest, 'r', encoding='utf-8') as file:
        latest = json.load(file)
    if args.ignore:
        with open(re.sub(r"^-", location, args.ignore), 'r',
                  encoding='utf-8') as file:
            ignore = json.load(file)
    else:
        ignore = {}

    changeset = get_changeset(re.sub(r"^-", location, args.current), latest,
                              ignore)
    if not args.no_out:
        output_changeset(args.out, args.format, changeset)

    if args.update:
        branch = datetime.now().strftime(args.branch)
        changes = process_updates(changeset, args.destpath, repo,
                                  branch, args.dry_run)
        if changes:
            if not args.dry_run:
                update_inventory(args.scripts, args.destpath)
            print(f">>> Total updates: {changes} <<<")
        else:
            print("No changes to publish")
            sys.exit(0)

        if args.pr:
            url = generate_pr(changeset, repo,
                              args.clone.split(":")[-1].rsplit(".", 1)[0],
                              datetime.now().strftime(args.pr_title),
                              pr_template.render(dependencies=changeset),
                              branch, 'main')
            print(f"Updates ({changes}) submitted as PR {url}")


if __name__ == '__main__':
    main()
