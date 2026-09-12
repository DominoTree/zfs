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
#	Verify an error logged after the pool has processed an async destroy
#	is recorded where an error scrub can find it.
#
# STRATEGY:
#	1. Create a pool with a file in it.
#	2. Create and destroy a dataset, and wait for the async destroy to be
#	   processed.  That runs dsl_scan_sync() with no scan in progress.
#	3. Inject checksum errors and read the file, so an error is logged
#	   outside any scan.
#	4. Verify an error scrub finds it.  It only reads the last error log,
#	   so an error misfiled into the scrub error log is invisible to it.
#

verify_runnable "global"

function cleanup
{
	log_must set_tunable32 SCAN_SUSPEND_PROGRESS 0
	log_must zinject -c all
	destroy_pool $TESTPOOL2
	rm -f $TESTDIR/vdev_a
}

log_onexit cleanup

log_assert "An error logged after an async destroy is reachable by scrub -e."

truncate -s $MINVDEVSIZE $TESTDIR/vdev_a
log_must zpool create -f $TESTPOOL2 $TESTDIR/vdev_a

typeset file=/$TESTPOOL2/$TESTFILE0
log_must dd if=/dev/urandom of=$file bs=1M count=1
log_must sync_pool $TESTPOOL2

log_must zfs create $TESTPOOL2/$TESTFS1
log_must dd if=/dev/urandom of=/$TESTPOOL2/$TESTFS1/$TESTFILE0 bs=1M count=8
log_must sync_pool $TESTPOOL2
log_must zfs destroy $TESTPOOL2/$TESTFS1
log_must zpool wait -t free $TESTPOOL2

log_must zinject -t data -e checksum -f 100 -am $file
dd if=$file of=/dev/null bs=1M count=1 || true
log_must sync_pool $TESTPOOL2
log_must zinject -c all

log_must set_tunable32 SCAN_SUSPEND_PROGRESS 1
log_must zpool scrub -e $TESTPOOL2
log_must is_pool_error_scrubbing $TESTPOOL2 true

log_pass "An error logged after an async destroy is reachable by scrub -e."
