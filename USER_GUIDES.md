# USER GUIDES — Elsewedy Sales CRM

---

## 1. SALES REPRESENTATIVE GUIDE

**Your day starts on "My Day".** It lists today's call sheet — every lead whose
follow-up is due, overdue ones first. The bell (top right) reminds you of overdue
follow-ups and VIP leads that need contact NOW.

**Managing leads.** You see only the leads assigned to you. Open any lead to update
it. You can change: status, follow-up date & time, qualification, industry,
offer-sent, notes, activity log, and (when won) the deal value, sold area and plot
number. You cannot add, delete, or reassign leads — Marketing adds them, Sales
Operations / your manager assigns them.

**Updating statuses.** Statuses are grouped into *Contact attempt* (No Answer,
Wrong Number, Call Back…) and *Sales progress* (Offer Sent – Following Up,
Scheduled Meeting, Site Visit Scheduled…). Three statuses — **Call Back, Scheduled
Meeting, Site Visit Scheduled** — require a date, a time, AND notes before you can
save. Follow-up-type statuses require at least a date. This is what fills your
calendar automatically.

**VIP rule.** A VIP lead must get first contact within 4 hours of assignment
(any status update, WhatsApp, or email from the CRM counts). Overdue VIPs alert
you and escalate to your manager.

**Scheduling meetings & site visits.** Set the status, date, time and notes → on
save, an email draft opens addressed to you, your manager, and (if enabled) the
Sales Director — plus the site manager for site visits. Send it with one click.
The event appears on your Calendar instantly.

**Using WhatsApp & Email.** Inside any lead, the "Contact the client" panel offers
5 templates (Introduction, Follow-Up, Offer Sent, Meeting Confirmation, Site Visit
Confirmation) pre-filled with the client's details. Edit the text, then press
WhatsApp (opens the chat with your message ready) or Email client.

**Qualification.** Set Qualified/Unqualified; if Qualified, choose the temperature
(Hot/Warm/Cold). Notes explaining *why* are mandatory.

**Losing a deal.** Marking a lead Lost requires a reason category (Price /
Not Interested / Competitor / Location) and a detailed reason. Be honest — this
feeds the loss-analysis reports that improve our offering.

**My Report** shows your funnel, sources, conversion rate and target progress.

---

## 2. SALES MANAGER / SECTION HEAD GUIDE

**Team monitoring.** Team Day shows your team's follow-up load, overdue counts,
VIP overdue and neglected leads. Team Reports covers your team only.

**Calendar.** The Calendar tab shows every callback, meeting and site visit for
your whole team — filter by member, switch Daily/Weekly/Monthly.

**Workload management.** In Team Reports, the Workload & Response dashboard shows
per member: active leads, pipeline leads, SQM handled, expected value, meetings,
follow-ups due, conversion %, average response time, neglected leads, leads
reassigned away, and a workload percentage. Use it to balance assignments.

**Reassignment.** You can reassign leads within your team (open a lead → Assigned
to; or bulk-select in Leads). You cannot touch other teams. Auto-reassignment
(settings): leads not contacted within 48h get flagged, you're notified, and if
the setting is ON the system reassigns them fairly automatically.

**Confirmations.** External-sales submissions from your team await your Confirm.
You also receive meeting/site-visit notifications for your reps.

**Your team.** On the Hierarchy tab, "My team — add who reports to me" lets you
claim unplaced members. Only the administrator can move someone between teams.

---

## 3. MARKETING GUIDE

**Uploading leads — three ways** (Excel & Data page):
1. **Smart paste** — copy the email form (one or many leads) into the paste box.
   The system parses the fields, translates Arabic names, cleans phone numbers to
   international format, flags duplicates, and (if auto-assign is ON) distributes.
2. **Excel upload** — download the template (it includes a Phone Format Guide
   sheet), fill it, upload. Phone numbers are auto-corrected; ones that can't be
   are highlighted for you after import.
3. **Manual** — the + Add lead button anywhere.

**Auto assignment** is OFF by default. You or Sales Operations can switch it on
with the checkbox next to the upload tools — when ON, new leads distribute
automatically balancing workload, SQM, and pipeline.

**Monitoring campaigns.** Team Reports gives you: channel conversion (leads,
won, conversion %, revenue AND SQM sold per source), the marketing performance
section (weekly/quarterly/yearly), lead-source analysis, and loss reasons by
source. What you can't see — by policy — is operational sales data: calendars,
meetings, site visits, and follow-up schedules are hidden from marketing, and
you receive no meeting notifications.

---

## 4. ADMINISTRATOR (HR) GUIDE

**User management.** People sign up themselves from the login page and appear on
your Team page as **Pending** with zero access. Open each one → set access level,
title, department (and phone for notifications) → Save = approved. "Disable
access" revokes sign-in without deleting history. At least one admin must
always exist.

**Roles available:** Sales, Manager, Sales Director, Sales Operations, Marketing,
Marketing Manager, Finance/AR, CEO, CFO, HR Director, Admin.

**Assignment rules & automation** (Targets page → Automation settings): auto
assignment on/off, auto reassignment on/off, VIP SLA hours, neglect limit hours,
workload capacity, site manager email, director notifications. The Sales Director
can also change these from Team Reports — including the special switch that
grants YOU calendar access (by default the administrator cannot see sales
calendars and receives no meeting notifications).

**Reporting.** You view everything: all leads, all reports, exports, targets,
hierarchy, the AR cash cycle. You cannot add/edit/delete/reassign leads — that
separation is enforced by the database itself, not just the interface.

**Supabase housekeeping.** Password resets, pre-creating users, and data
erasure/restoration happen in the Supabase Dashboard (Authentication / Table
Editor). See DEPLOYMENT_GUIDE.md.
