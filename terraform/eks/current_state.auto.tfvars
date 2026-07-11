# This is the ONLY file the SRE agent is expected to edit for the
# fault-injection / fix demo beat. One boolean drives both parts of the
# fault (node group min/max size AND a scheduling-blocking taint — see
# eks.tf for why both are needed), so the fix really is a one-line revert.
fault_active = false
