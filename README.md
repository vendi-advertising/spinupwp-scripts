# SpinupWP Scripts

The following are some scripts that we use on our SpinupWP sites/servers. They should all broadly
work on other platforms, however they do make certain assumptions about how SpinupWP creates
servers and you might need to make some tweaks.

## Warning

As with everything from random people on the internet, read these scripts thoroughly
before just running them.

## Bash notes

I fully admit that I'm not a Bash-guru in any way, however these scripts were run through
[ShellCheck](https://www.shellcheck.net/), so syntactically they should at least be valid.

I will also admit that I prefer obviousness and verbosity when it comes to my scripts, so
you will find that I often create variables for everything, and then compose other
variables from those variables.

## Scripts

### ImunifyAV

This script is used to install ImunifyAV server-wide. After installation it will also create
a new script called `imunify-login.sh` in the same directory which will give you a one-time-login
link to sign into the admin interface. Both scripts must be run as root or via `sudo`.

* [Install script](./install-imunifyav.sh)
* [SpinupWP thread](https://community.spinupwp.com/c/suggestion-box/one-click-install-for-imunifyav)

#### Variables

##### `IMUNIFY_SITE_DOMAIN`

The domain that the web interface will be accessed from. This variable is used in two primary locations:

1. SpinupWP uses the (original) primary domain in the file system path, and we use it to
   determine where to install ImunifyAV. Specifically:<br />
   `IMUNIFY_SITE_PATH=/sites/${IMUNIFY_SITE_DOMAIN}/files/${IMUNIFY_SITE_INSTALL_FOLDER_NAME}`
2. In the one-time-login script to give a clickable URL.<br />
   `echo "https://\${IMUNIFY_SITE_DOMAIN}/#/login?token=\${IMUNIFY_LOGIN_TOKEN}"`

##### `IMUNIFY_SITE_INSTALL_FOLDER_NAME`

The subfolder to install relative to `~/files/`. Default is `imav`. See `IMUNIFY_SITE_DOMAIN`
for specific usage.

##### `IMUNIFY_USER`

The user account that the site runs as. I'm actually not 100% certain this is required and might just
be a remnant from a prior tutorial. This value gets written to the config file as:

```
[paths]
ui_path = ${IMUNIFY_SITE_PATH}
ui_path_owner = ${IMUNIFY_USER}:${IMUNIFY_GROUP}
```

##### `IMUNIFY_GROUP`

The group account that the site runs as. Default is the same as `IMUNIFY_USER`. See `IMUNIFY_USER`
for specific usage.

##### `IMUNIFY_PHP_VERSION`

The PHP version that will run the web interface. Imunify requires `proc_open` and `proc_close` so we
need to open that for our specific version of PHP, and we then need to restart the PHP service.

```bash
sed -i -e 's/proc_open,//;s/proc_close,//' /etc/php/${IMUNIFY_PHP_VERSION}/fpm/php.ini
service php${IMUNIFY_PHP_VERSION}-fpm restart
```

#### Running

##### Installation

```bash
sudo bash ./install-imunifyav.sh
```

##### One-time-login

```bash
sudo ./imunify-login.sh
```
