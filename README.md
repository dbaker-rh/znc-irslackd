# znc-irslackd

Single docker container that runs both znc and irslackd on OpenShift.


TLS caveats:

* In order for IRC over SSL to pass through the OpenShift router, we must use "TLS passthrough" rather than "edge".
* This means the cert inside the container cannot leverage the (presumed) valid cert on the cluster itself (We generate a self-signed cert internally - a future enhancement if running outside of a private network is to leverage certbot/letsencrypt to generate a live cert)
* This also means your IRC client needs to support SNI.


HexChat notes:

* I use hexchat on a RHEL7 desktop.  The latest version in the repos is an elderly 2.10.2 which does not support SNI.
* However, with one minor addition (add plugins/lua.so to the %files section), the SRPM's .spec file will successfully build 2.12.0 through .3 which all support SNI.


znc caveats:

* Mostly cloned from upstream https://github.com/znc/znc-docker but updated to use fedora.
* I do not follow ZNC's recommendation and drop an initial/empty config into place before first use.
* The rolling deployment strategy usually causes znc to detect the old file lock - we forcefully break the lock if needed in order to start.



irslackd caveats:

* Slack's online/away doesn't integrate very well (I often get emailed messages I already saw).
* Slack "user responses" come as messages, not icon additions.
* Slack "user deleted message ..." comes as-is, doesn't delete the message.
* Slack sub-threads are somewhat hard to follow (disable threads to help with this).
* Slack channel topics don't appear to be changeable.
* Probably some other stuff



Quick start (OpenShift 3.11):

* oc login https://.... --token=....
* oc new-project znc
* oc new-app -f https://raw.githubusercontent.com/dbaker-rh/znc-irslackd/master/openshift-template.json
* or, from a checked out copy ... oc new-app -f openshift-template.json
* oc start-build znc-irslackd-build
* Take note of the default URL and initial znc password, and log in to the URL shown using "admin".  Use this, or create a new znc user for your use.
* oc logs -f bc/znc-irslackd-build   # wait/watch for completion of the initial build
* Create a new router manually if you desire something other than the default URL.


Optional:

Upload the template for (re)-use: oc create -f openshift-template.json -n namespace



Still to come:

* Easier backup/restore of ZNC configs between installs.  It might be easier to script "/znc ..." config parameters from an IRC client to populate desired config for this.
* Better internal SSL cert management.


