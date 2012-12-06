Web based tool for rapid stylesheet development with live preview and debug information.


![Styler screenshot](https://dl.dropbox.com/u/25033309/styler_screenshot.png "Styler screenshot")


Introduction video from LxJS: <http://www.youtube.com/watch?v=2VSU4gjxYpU>


### Installation

```
[sudo] npm install -g styler
styler --help
styler
```

### Getting started

Once you have Styler running you need to connect your own webpage to it. Follow the directions on the Styler frontpage to do that.

If your connecting to the site for the first time you need to make a new project for it.

**Base URL**

Defines what pages are part of the project. You would usually want to set it to the domain name you are using so that all the subpages also work.

**Source locations**

Mappings between the URLs you page is using and the folders from your hard drive containing the source files. You have to make sure they are in the right level. For example if your URL is `http://mydomain.com/css/` it matches the path `/path/to/my/app/public_dir/css` and if the URL is just `http://mydomain.com/` it means matching path is `/path/to/my/app/public_dir`.

All paths are automatically validated. If you see green checkmarks you have probably found the correct folder.

If you want Styler to automatically create source files based on the stylesheets it sees on the page set the Source folder to an empty directory.

### Tutorials

[Live preview in iOS/Android](https://github.com/tonistiigi/styler/issues/13)

More tutorials and a list of features are on the way. If you get into trouble start a new issue.


### Command line options

**allowed** - For security reasons by default Styler only allows local connections. If you want to allow other computers to connect(either as clients or controllers) you must list their IPs(or wildcards) in here.

**root** - Styler can't access files outside this directory. Defaults to `/` or primary hard drive on Windows.

**port** - Server port. Defaults to `5100`.

**log** - One of debug, info, notice, warning, error. Defaults to `info`.

**nologfile** - Switches off writing debug log files. These logs will be never sent but they may be useful if you want to report (crashing) bugs.

**reset** - Clear all previous projects info and configuration.

**pfx** - Directory where the configuration is saved/loaded. Defaults to your user directory.


### Building from source:

```
git clone https://github.com/tonistiigi/styler.git styler
cd styler
git submodule update --init --recursive
npm install
lib/backend/styler --help
lib/backend/styler
```

