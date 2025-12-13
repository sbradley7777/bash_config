#!/bin/sh
logger -t "ClusterMon-External" "${CRM_notify_node} ${CRM_notify_rsc} ${CRM_notify_task} ${CRM_notify_desc} ${CRM_notify_rc} ${CRM_notify_target_rc} ${CRM_notify_status} ${CRM_notify_recipient}";
exit;

