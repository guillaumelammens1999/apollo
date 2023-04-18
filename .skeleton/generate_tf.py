#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader, Template
from pprint import pprint
import yaml
import json
import sys
import argparse
import os
import datetime
from git import Repo
from git.exc import *
import random
import string
import shutil


def _random(length=8):
    result = ''.join(
            random.choices(
                string.ascii_uppercase + string.digits, 
                k=length
            )
        )
    return result


def find_files(dir, ext=".tf"):
    tf_files = []
    for dirpath, dirnames, filenames in os.walk(dir):
        for filename in [f for f in filenames if f.endswith(ext)]:
            tf_files.append(os.path.join(dirpath, filename))
    return tf_files


def import_yaml(src_file):
    try:
        with open(src_file) as file:
            result = yaml.load(file, Loader=yaml.FullLoader)
        return result
    except IOError:
        print(f"Can't find or read file {src_file}")
        sys.exit(1)
    except Exception as e:
        print(e)
        sys.exit(1)


def parse_repos(stack, repos):
    try:
        repo_url = repos[stack]
    except KeyError:
        print(f"stack ({stack}) is not in the module_repos.yaml")
        repo_url = f"ssh://git@github.com/SentiaBE/aws_{stack}.git"
    return repo_url


def global_variable(params, tf_files, repos, git, tpl, force=False):
    for tf_file in tf_files:
        if "global_variables" in tf_file:
            # combine variables with solution
            env = Environment(loader=FileSystemLoader(
                './'), trim_blocks=True, lstrip_blocks=True)
            template = env.get_template(tpl + tf_file + '.tpl')

            if not git.endswith('/'):
                git = git + '/'
                
            # creates stacks dir
            os.makedirs(f"{git}stacks/", exist_ok=True)

            # write customized template
            filename = f"{git}stacks/{tf_file}"
            if not force:
                if os.path.isfile(filename):
                    print(
                        f"file: '{filename}' already exists, will not overwrite!")
                    continue
            try:
                file = open(filename, "w")
                file.write(template.render(params))
            except IOError:
                print(f"Unable to write to file {filename}")
                sys.exit(1)
            finally:
                file.close()
    return filename.split('/')[-1]


def tf_create(params, tf_files, repos, git, tpl, global_variables_file, force=False):
    for key_stacks, value_stacks in params['stacks'].items():
        for stack in value_stacks:
            for tf_file in tf_files:
                if "global_variables" in tf_file:
                    continue
                # combine variables with solution
                env = Environment(loader=FileSystemLoader(
                    './'), trim_blocks=True, lstrip_blocks=True)
                template = env.get_template(tpl + tf_file + '.tpl')

                if not git.endswith('/'):
                    git = git + '/'
                    
                # creates stacks dir
                os.makedirs(f"{git}stacks/{key_stacks}/{stack}", exist_ok=True)

                # write customized template
                filename = f"{git}stacks/{key_stacks}/{stack}/{tf_file}"
                if not force:
                    if os.path.isfile(filename):
                        print(
                            f"file: '{filename}' already exists, will not overwrite!")
                        continue
                try:
                    file = open(filename, "w")
                    file.write(template.render(params, stack=stack))
                except IOError:
                    print(f"Unable to write to file {filename}")
                    sys.exit(1)
                finally:
                    file.close()
            # Create symlink for the global variables file
            try:
                os.symlink(f"../../{global_variables_file}",
                           f"{git}stacks/{key_stacks}/{stack}/{global_variables_file}")
            except OSError:
                print(f"unable to create symlink for {global_variables_file}")
            # get repo url
            repo_url = parse_repos(stack, repos)
            rand = _random()
            os.makedirs(
                f"{git}stacks/{key_stacks}/{stack}/{rand}", exist_ok=True)
            # get a skeleton from the modules repo
            try:
                #git.Git(f"{git}stacks/{stack}").clone(repos[stack])
                Repo.clone_from(
                    repo_url, f"{git}stacks/{key_stacks}/{stack}/{rand}")
                # list files
                tf_files_git = find_files(
                    f"{git}stacks/{key_stacks}/{stack}/{rand}/.skeleton/")
            except GitError:
                print(f"unable to clone git repo for stack: {stack}")
                continue
            # copy skeleton files
            try:
                for tf_file in tf_files_git:
                    filename = f"{git}stacks/{key_stacks}/{stack}/{tf_file.split('/')[-1]}"
                    if not force:
                        if os.path.isfile(filename):
                            print(
                                f"file: '{filename}' already exists, will not overwrite!")
                            continue
                    shutil.copy(tf_file, filename)
            except shutil.Error:
                print("unable to copy")
            finally:
                shutil.rmtree(
                    f"{git}stacks/{key_stacks}/{stack}/{rand}", ignore_errors=True)


####


def main(argv=[]):
    # specify command line options
    parser = argparse.ArgumentParser(
        description='Sentia init')
    parser.add_argument("--git-path", dest="git",
                        help="path to put newly created terraform files - default: '../'", 
                        required=False, default="../")
    parser.add_argument("--template-path", dest="template",
                        help="path where templates are located - default: 'templates/'", 
                        required=False, default="templates/")
    parser.add_argument("-f", "--files", dest="tf_files", help="a list of stacks.",
                        required=False, nargs='+', default=["main.tf", "base_variables.tf", "global_variables.tf"])
    parser.add_argument("--config", dest="yaml_config", 
                        help="this configfile superseeds other parameters like account, customer, project and stack", required=False)
    parser.add_argument("--force", dest="force",
                        help="forces recreationg of files", action="store_true")

    args = parser.parse_args()

    # do not combine account,customer,project,stack with yaml_config
    if args.yaml_config:
        params = import_yaml(args.yaml_config)
    else:
        print('not all required parametes are filled in')
        sys.exit(0)

    repos = import_yaml("module_repos.yaml")

    # set global variables
    global_variables_file = global_variable(
        params=params,
        tf_files=args.tf_files,
        repos=repos,
        git=args.git,
        tpl=args.template,
        force=args.force
    )

    # Create terraform template
    tf_create(
        params=params,
        tf_files=args.tf_files,
        repos=repos,
        git=args.git,
        tpl=args.template,
        global_variables_file=global_variables_file,
        force=args.force
    )


if __name__ == '__main__':
    main()
