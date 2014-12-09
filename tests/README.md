# Automated tests for QA Automation tools

How to set it up locally is described [here](http://portal.qa.suse.cz/wiki/development/qa_tools_testing/qa_tools_testing_kvm/). The tests are also run automatically from [jenkins](http://jenkins.qa.suse.cz:8080). You can ask jenkins to run tests for specific branch (qa-automation-manual-branch-check) or it runs it automatically for pull requests.

Since the code is not commented well, I will give at least some hints:

- Code is in tests/utils/virttest/virttest3. This is python3 code, which is not supported by robot well. so as part of the testrun, it is converted to python2 tests/utils/virttest/virttest2.
- Main object it TestBox. This is instance of entire test network, including hosts, etc.
- Most of the work is done by filling templates (kiwi, libvirt, etc.). So the code in general reads configurations, than prepare template data, fills the data to the (correct) template and call some command with result file(s). all templates are in tests/utils/virttest/templates and are processed by [jinja2](http://jinja.pocoo.org/). **Everything** in this directory is expected to be processed by jinja2. So example workflow to create SUT:
    1. Load testbox state from disk.
    2. Read data from testbox, find available IP, hostname, etc.
    3. Unless image for this type of sut is already created, use data to proces jinja template to generate image description for KIWI
    4. run kiwi to generate image
    5. process jinja2 template for libvirt to generate new VM xml
    6. run libvirt to create the new VM
    7. save testbox state to disk
    8. return sut hostname and finish

However many things can be improved to make it fully useful:

## Documentation ;-) 

Sorry, I did not make it in time

## Allow parallel run (kiwi build and rpmbuild) and fix builing of other types of images

The virtest itself is desicgned to be run in parallel (you can configure multiple networks to use -> each network = one parallel test). The server we have (saturn.qa.suse.cz) is powerful to run 5-10 tests in parallel. However, kiwi and rpm building cannot run in parallel (well it does, but keeps fighting for locks -> takes much longer than running in serial). Also it is not possible to build sle12 images by kiwi, since it requires to run kiwi on sles12...

This can all be easily fixed (parallel, all types of images) by running kiwi and build in linux containers (LXC). So to build kiwi image for sles12, it will be build in LXC with sles12, etc. Also each parallel tests will have its own set of LXC -> for kiwi, it will ne running isolated. This way it is possible to run tests in parallel.

[How to run kiwi in lxc](https://github.com/openSUSE/kiwi/wiki/Building-images-inside-a-LXC-container). Similar approach can be used to run rpm builing.

Also, when it will use LXC for test preparation, it might (not checked) possible to replace KVM VMs with LXC (so tests will use LXC instead of KVM VMs). Kiwi can build both KVM and LXC images, so it should only need to change jinja2 templates to LXC and let libvirt+kiwi handle the rest. LXC should be faster and require less resources than KVM (but the isolation is not that good - which might not be needed for our tests)

## Use build cache in kiwi

Kiwi allows to use build cache to build similar images (just with some added rpms) faster. This is currently not done, but I can imagine that it can be used to have basic sles-11-sp3-pure (no automation) image and use it as cache for sles-11-sp3-hamsta sles-11-sp3-server sles-11-sp3-sut, etc. So when some more advanced image is build, it checks whether the -pure version exist. If not, than it is build. Than it is used as cache.

See [kiwi documentation](http://doc.opensuse.org/projects/kiwi/doc/#chap.caches) to read more about cache.

## Upgrade images

Similar to previous one, when new packages are built, it should not be necessary to completely rebuild images. Kiwi support upgrade of images (build with newer rpm). This shoul greatly increase speed of image rebuild when new rpms are build. In fact, currently the images are not rebuild at all, so you need to manually reset the network (utils/98_delete_virtenv) to make images rebuild.

[Documentation about upgrading images](http://doc.opensuse.org/projects/kiwi/doc/#chap.maintenance)



## Note

To make OSC buils successful, make sure that you trust all needed projects. Add following (or similar) to .oscrc in your "test" node:

trusted_prj=SUSE:SLE-11:GA SUSE:SLE-11-SP3:GA SUSE:SLE-11-SP1:GA SUSE:SLE-11-SP3:Update SUSE:SLE-11-SP1:Update SUSE:SLE-11:Update SUSE:SLE-11-SP2:GA SUSE:SLE-11-SP2:Update SUSE:SLE-12:GA

