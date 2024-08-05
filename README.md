# Ansible Role: SequenceServer

[![CI](https://github.com/abims-sbr/ansible-sequenceserver/workflows/CI/badge.svg?branch=master)](https://github.com/abims-sbr/ansible-sequenceserver/actions?query=workflow%3ACI)
[![SequenceServer version](https://img.shields.io/badge/SequenceServer%20version-2.0-green.svg)](https://github.com/wurmlab/sequenceserver)
[![Developers](https://img.shields.io/badge/Developers-ABiMS-blue.svg)](https://abims.sb-roscoff.fr)

An Ansible Role that installs [SequenceServer](https://sequenceserver.com) on Linux (tested with Ubuntu 20) and deploys one [NCBI BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download) server for each BLAST database, with the following features:
- The BLAST jobs are submitted on a [SLURM](https://slurm.schedmd.com/) HPC cluster.
- The server are reverse-proxied with NGINX. Restricted access can be configured for private servers, by querying an ldap server.
- The SequenceServer interface can be minimaly customized (logo, title, support link).

## Requirements

The host must be configured as a SLURM-client and the SequenceServer user must have a SLURM account to be able to submit jobs on the SLURM HPC cluster.
How to install and configure a SLURM HPC cluster is beyond the scope of this role.

The NCBI BLAST+ tools must be available on the host and on the SLURM HPC cluster (with `module load blast`). They can be installed with [Conda](https://bioconda.github.io/recipes/blast/README.html?blast). BLAST databases must be formatted with `makeblastdb` (see https://sequenceserver.com/doc/#database)

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Version of the ruby gem to install (>= 2.0.0)
sequenceserver_version: 3.1.2
```
Variable to set the version of SequenceServer to install. This role can be used with SequenceServer version >= 2.0.0.

```yaml
sequenceserver_blast_db:
    - name: 'my_db'
      port: '4567'
      path: '/path/to/my/db'
      users: ['fbar','jsmith']
      web_page_title: 'blablabla'
      placeholders: [{key: 'key1', value: 'value1'}, {key: 'key2', value: 'value2'}]
      conf_options: [{key: 'job_lifetime', value: '10080'}, {key: 'databases_widget', value: 'tree'}, {key: 'options', value: {'blastn': {'default': ['-task blastn', '-evalue 1e-5'], 'short-seq': ['-task blastn-short', '-evalue 1e-1']}}}]
```
This is the variable used to define the BLAST databases.

For each element of the list (each database) will be generated a BLAST server accessible at the url http://hostname/my_db (where "hostname" is the name of the server provided in the inventory and "name" is the name of the database provided in the `sequenceserver_blast_db` variable). Each BLAST server is managed with a systemd service called "sequenceserver-`name`.service" (configuration in `/etc/systemd/system/`).

If the BLAST server needs another reverse-proxy, it might be needed to add a directive to edit the response header "location" in order to get the right URL for the results page (see [issue#464](https://github.com/wurmlab/sequenceserver/issues/464)). For example, with an apache reverse-proxy:
```
<LocationMatch "^/(?<instance>[^/]+)/">
   Header edit Location "(^http[s]?://)([a-zA-Z0-9\.\-]+)(:\d+)?/(%{MATCH_INSTANCE}e/)?" "/%{MATCH_INSTANCE}e/" env=MATCH_INSTANCE
</LocationMatch>
```

Each database is defined as a dictionary of the following parameters:
- `name` A unique name for the database, used in the URL
- `port` A unique unused port
- `path` Absolute path to the directory where one or multiple formatted databases are located
- `users` Optional. Useful if the database needs restricted access. List of authorized users (LDAP "uid").
- `ldap_businesscategory` Optional. Useful if the database needs restricted access. A ldap businessCategory value. LDAP users with this "businessCategory" value will have access to the database.
- `group` Optional. Useful if the database needs restricted access. An LDAP group ("gid"). LDAP users who are member of this group will have access to the database.
- `web_page_title` Optional. The title displayed at the top of the web page. If not provided, the default title is "BLAST server for `name`".
- `placeholders` Optional. A list of placeholder dictionaries `{key: 'key_item', value: 'value_item'}` that are used to customize top or bottom supplementary HTML code (see `sequenceserver_top_web_page_html_path` and `sequenceserver_bottom_web_page_html_path`). For example `placeholders: [{key: 'key1', value: 'value1'}, {key: 'key2', value: 'value2'}]`.
- `conf_options` Optional. A list of supplementary SequenceServer configuration options as dictionaries `{key: 'key_item', value: 'value_item'}` (see [SequenceServer documentation](https://sequenceserver.com/doc/#basics)). For example `[{key: 'job_lifetime', value: '10080'}, {key: 'databases_widget', value: 'tree'}, {key: 'options', value: {'blastn': {'default': ['-task blastn', '-evalue 1e-5'], 'short-seq': ['-task blastn-short', '-evalue 1e-1']}}}]`

Unique `name` and `port` are mandatory for each database.
`users`, `ldap_businesscategory` and `group` are optional and can be used to add an authentication layer with the nginx-auth-ldap module. Choose one single authentication mode for each database.
The BLAST server title can be customized with the `web_page_title` parameter. If not provided, the default title is "BLAST server for `name`".

SequenceServer logs are stored in `/var/log/sequenceserver/sequenceserver.log`.

```yaml
# Version of BLAST to use in sequenceserver (called with "module load" in the slurm bash script)
sequenceserver_blast_version: 2.14.0
# Absolute path to the blast binaries
sequenceserver_blast_binaries: "~/conda3/envs/blast-{{ sequenceserver_blast_version }}/bin"
# --cpus-per-task (SLURM option)
sequenceserver_blast_threads: 4
# --mem (SLURM option)
sequenceserver_blast_mem: 16GB
```
Variables needed to configure SequenceServer and SLURM job options.

```yaml
# URL to get the logo image from
sequenceserver_logo_url: ""
# Local file path to the logo image
sequenceserver_logo_path: ""
# URL the logo will point to
sequenceserver_home_url: "http://sequenceserver.com"
# URL the "Help and support" icon will point to
sequenceserver_support_email: "http://www.sequenceserver.com/#license-and-support"
# Path to the file containing the supplementary HTML code to display at the top of the web page
sequenceserver_top_web_page_html_path: "~/top_web_page.html"
# Path to the file containing the supplementary HTML code to display at the bottom of the web page
sequenceserver_bottom_web_page_html_path: "~/bottom_web_page.html"
```
These variables allow to customize the BLAST server web page. They are optional.
Two variables are available to set the logo displayed on the BLAST server: `sequenceserver_logo_url` or `sequenceserver_logo_path`. If both are set, the logo given with `sequenceserver_logo_path` will override the logo given with `sequenceserver_logo_url`.
If the files `sequenceserver_top_web_page_html_path` or `sequenceserver_bottom_web_page_html_path` exist, their content will be added in the base RUBY template used to display the web page and will be rendered at the top and bottom of the web page. These files must contain HTML code. This can be used, for example, to display information or warning messages to users (service shutdown, etc).
Placeholders set in the database parameter `placeholders` (see above) can be used to customize the HTML code in these files. For example, if the database has the parameter `placeholders: [{key: 'key_item', value: 'value_item'}]`, the snippet `<% if defined?(SequenceServer::Key_item) %><%= SequenceServer::Key_item %>` will be replaced by the string `value_item` in the rendered HTML code. Please note that the first letter must be upper case in the snippet to be correctly interpreted as a Ruby constant by SequenceServer.

```yaml
# User running the sequenceserver service (systemd) and running SLURM blast jobs
sequenceserver_user: "sequenceserver"
```
Variable to define the user running the sequenceserver service and submitting the SLURM jobs. This user must have a SLURM account.

```yaml
# NGINX version to install, from https://nginx.org/packages/mainline
sequenceserver_nginx_version: 1.25.5
# proxy_read_timeout (nginx directive)
sequenceserver_proxy_read_timeout: 180
# Authentication with LDAP - Mandatory if users or groups are used in variable sequenceserver_blast_db
# Sequenceserver_ldap_url: "ldap://ldap.my-domain.org/o=my-domain,c=org?uid?sub?"
sequenceserver_ldap_url: ""
```
Variables to configure the NGINX reverse-proxy.
`sequenceserver_ldap_url` must be set if one of the database has restricted access (use of parameter `users` or `group` in `sequenceserver_blast_db`).

## Dependencies

Roles:
 - [nginxinc.nginx](https://galaxy.ansible.com/nginxinc/nginx)
 - [geerlingguy.git](https://galaxy.ansible.com/geerlingguy/git)
 - [geerlingguy.ruby](https://galaxy.ansible.com/geerlingguy/ruby)

## Example Playbook

```yaml
- name: sequenceserver | install blast server
  hosts: blast_server
  roles:
    - abims_sbr.sequenceserver
```

## License

MIT License

## Author Information

This role was created in 2020 by [Loraine Brillet-Guéguen](https://github.com/loraine-gueguen)
