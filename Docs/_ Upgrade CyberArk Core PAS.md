This note describes the steps you need to take to upgrade a CyberArk Core PAS environment and all of its components in a Primary-DR setup. Clustering and Distributed Vaults are out of scope of this note.

This note is written from experience with real world customer environments, and is written for change management in mind. Official documentation does not cover impact analysis, backup or fallback plans.

We will upgrade the components in the following order:
- Primary Vault
- DR Vault
- PVWA
- CPM
- PSM
- PSMP / PSM for SSH

It's recommended that you validate your backups and checking up on your DR/BC processes before every upgrade.
Not that you can (or should) run a business continuity drill before every upgrade, but test occasionally according to your own (or your customers) risk appetite. Nevertheless, you should have a business continuity plan in case the environment becomes FUBAR.
If there's something that needs amending or adding to the plan, now is the time.

Before upgrading the Primary Vault, I highly recommend taking a full backup using PAReplicate the day before the upgrade.
Another thing I recommend is to take a separate full backup using PAReplicate immediately before the upgrade, by having a separate backup user that is added to the PSMRecordings safe (and any other heavy safe that's not business critical) with no safe authorizations; that way, the user can't read from the safe, reducing the size and time it takes to perform a full backup of the Vault.

**When upgrading the Vault, the recommended (and the only supported) approach is to first upgrade the Primary Vault** and then the DR Vault. This requires downtime, which must be communicated to the business/customer.
It is also possible to upgrade the DR Vault first, so that you can upgrade the DR Vault during office hours and the Primary Vault during off hours. This is however unsupported and if the database schema has been updated as part of the version upgrade, you risk that the DR Vault is unable to start. If that happens, you need to uninstall the new Vault software and install the older version again.
I will however say that I have upgraded customer prod vaults several times using this approach, saving them downtime. If there's no errors when trying it in a test environment, and you follow the failover/failback process just like on prod, it should (fingers crossed) be safe to do it on prod.

If possible, upgrade the Primary Vault first, because failover/failback is a mess anyway. Saves you hours of work when working on big vaults. Plus, you're following the supported approach and can get help from CyberArk support if stuff breaks.

# Format
These are all real-world change requests sent to customers inside of our PSA (Datto AutoTask PSA), and follows the limitations set by the PSA. Change requests inside of AutoTask PSA are divided into six sections:
- Description: Basic rich text formatting
- Impact Analysis: Plain text
- Implementation Plan: Plain text
- Test and Verification Plan: Plain text
- Fall Back Plan: Plain text
- Review Notes: Plain text

As all but the Description section is without text formatting of any sorts aside from line breaks, most of the change requests are written to make it easier to read inside of AutoTask PSA. These notes are in markdown, but it was a priority that they be fully readable without any formatting of any kind.

**The change requests are written for techs only**. To make it easier to write change requests, we decided on an audience: **Techs who are able to perform an upgrade with supervision.**
That way, we avoid explaining too much and we avoid pigeon-holing you into a specific way to perform a task. Restarting services in PowerShell vs. running services.msc vs. clicking around the places you're used to is not important, what's more important is that the process is reliable.

I'm a fan of PowerShell, but we had the (very relevant) feedback from customers that they couldn't approve a change request that was essentially one big PowerShell script. As such, the process is not fully automated.

CyberArk PAM upgrades are pretty much fully automatable and CyberArk publishes Ansible playbooks on their GitHub for install and upgrades. Inside those Ansible playbooks are just plain PowerShell scripts. While I recommend automating as much as possible, CyberArk PAM upgrades have so many pitfalls and caveats that you really need to know every single customization you've made to your installations and how to redo them after any upgrade. **Let this be a warning, I made customers angry by attempting to automate too much and forget post-upgrade details**.

The format of each upgrade is as such:
- Checklist (Description)
	- Contains a milestone-based checklist that you, the performing tech can check.
		- If the PSA supports timestamping, checking the checklist can help document your time spent on the task.
		- This checklist is split into Pre and Post-actions, with Pre-actions containing actions to perform before the change window and Post-actions containing a mix of post-install configurations and validations.
		- Every checklist item is based on instructions found inside the change request.
		- There's always a final Post-action for a second person to review that the post-actions were completed correctly. That made sense in the PSA we used, as other people could not uncheck your items. Thus, the performing tech will check all of the boxes besides the very last, call in a peer and review the Post-action checklist - if everything was OK, the peer could check their box and give the customer assurance that someone else put their name out there and OK'd your work.
	- Contains boilerplate information about the hostname(s), current version, target version, important IP addresses that will be used to perform the upgrade. This is to generalize the change request such that you don't need to change the sections for every customer. It prevents basic mistakes like pasting other customers' Vault IP addresses into a change request.
	- Contains a description of the sections of the change request. This is to give us and the customer a quick glance over the headlines/phases of the upgrade. This must be updated manually if you write anything new to the change request, and as such can be quite fragile. It's been most useful on Vault upgrades to give myself an overview.
- Impact Analysis
	- A short description of the impact on user productivity or component functionality during the upgrade or if unexpected errors occur during the upgrade.
- Implementation Plan
	- The meat of the change request is in this section. The Implementation Plan is split into at least these three subsections: Pre-Upgrade, Upgrade and Post-Upgrade. I've made headlines that mostly correspond with the Checklist at the top, but it's not a one-to-one mapping.
	- To make it easy to read (and write), a lot of the instructions are standardized. "Ensure that", "Copy the files", "Edit 'FILENAME'", "On the 'X' server", "Restart service 'SERVICENAME'", etc.
	- When you need to test, we'll refer to the Test and Implementation Plan. If the upgrade is complex and multi-step, we'll refer to specific sections in the Test and Implementation Plan.
- Test and Verification Plan
	- Instructions to verify that the upgrade didn't fail, log names are specified for troubleshooting purposes
	- Instructions for validating functionality after the upgrade
- Fall Back Plan
	- When possible, multiple choices are offered. Everything but the Vault is assumed to be a VM, so a snapshot rollback will be recommended in most circumstances.
	- In real life, a snapshot rollback is rarely necessary. CyberArk upgrade packages are notoriously filled with bugs, so in many cases it's enough to just repair the installation if you see errors during the upgrade. Don't be scared to do a repair, because that's what CyberArk support will ultimately recommend you to do.
- Review Notes
	- We filled this section with downtime estimations, change scheduling and "estimated risk" (low/medium/high). This was included to appease a specific customer that needed such estimation, but it was very context-specific to the customer. Don't take it too seriously.


[Change - Upgrade Vault]

[Change - Upgrade PVWA]

[Change - Upgrade CPM]

[Change - Upgrade PSM]

[Change - Upgrade PSMP]

[Change - Upgrade AAM CP+CCP]

