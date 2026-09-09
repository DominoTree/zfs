#!/bin/ksh -p
# SPDX-License-Identifier: CDDL-1.0
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# https://opensource.org/license/CDDL-1.0.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/cli_root/zpool_scrub/zpool_scrub.cfg

#
# DESCRIPTION:
#	Verify error scrub reports an empty error log instead of exiting
#	silently with success, and that scrubbing every pool does not fail
#	over a pool that has nothing to do.
#
# STRATEGY:
#	1. Create a pool with nothing in its error log.
#	2. Request an error scrub and verify it fails and says why.
#	3. Request an error scrub of every pool and verify it succeeds.
#

verify_runnable "global"

function cleanup
{
	zpool scrub -s $TESTPOOL2 2>/dev/null
	zpool scrub -s $TESTPOOL 2>/dev/null
	destroy_pool $TESTPOOL2
	rm -f $TESTDIR/vdev_a
}

log_onexit cleanup

log_assert "Error scrub reports an empty error log."

truncate -s $MINVDEVSIZE $TESTDIR/vdev_a
log_must zpool create -f $TESTPOOL2 $TESTDIR/vdev_a

log_mustnot_expect "no recorded errors to scrub" zpool scrub -e $TESTPOOL2

log_must zpool scrub -e -a

log_pass "Error scrub reports an empty error log."
