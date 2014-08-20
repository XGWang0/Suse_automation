# Automated tests for QA Automation tools

The automated tests are intended to be run both automatically from CI (Jenkins), but also manually for help with development
TBD


set up jenkins

To make OSC buils successful, make sure that you trust all needed projects. Add following (or similar) to .oscrc in your "test" node:

trusted_prj=SUSE:SLE-11:GA SUSE:SLE-11-SP3:GA SUSE:SLE-11-SP1:GA SUSE:SLE-11-SP3:Update SUSE:SLE-11-SP1:Update SUSE:SLE-11:Update SUSE:SLE-11-SP2:GA SUSE:SLE-11-SP2:Update SUSE:SLE-12:GA

should work now

