# train-openshift - Train Plugin for connecting to Openshift

This plugin allows applications that rely on Train to communicate Openshift.  For example, InSpec uses this to perform compliance checks against Openshift infrastructure components.


## To Install this as a User

Train plugins are distributed as gems.  You may choose to manage the gem yourself, but if you are an InSpec user, InSPec can handle it for you.

You will need InSpec v1.7 or later.

Simply run:

```
$ inspec plugin install train-openshift
```

You can then run:

```
$ inspec detect -t opnshift://
== Platform Details

Name:      openshift
Families:  unix, os
Release:   train-openshift: v0.0.1
Arch:      -
```

