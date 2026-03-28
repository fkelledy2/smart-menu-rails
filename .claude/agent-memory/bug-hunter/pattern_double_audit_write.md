---
name: CRM reopen double audit write
description: LeadsController#reopen writes a lead_reopened audit after calling LeadTransitionService, which already wrote a stage_changed audit — two audit records per reopen
type: feedback
---

`Admin::Crm::LeadsController#reopen` calls `LeadTransitionService.call(new_stage: 'contacted')` and then immediately calls `Crm::LeadAuditWriter.write(event: 'lead_reopened')` on success. `LeadTransitionService#execute_transition` already calls `LeadAuditWriter.write(event: 'stage_changed')` internally. Every reopen therefore produces two audit records.

**Why:** Controller was written to mirror the `create` action pattern (which writes its own audit after save), but transition service already handles audit writing unconditionally.

**How to apply:** When `LeadTransitionService` is used, no additional audit write is needed at the call site. The `lead_reopened` event in `CrmLeadAudit::EVENTS` is redundant — either remove it or remove the explicit write from the controller. The simpler fix is to remove the explicit `LeadAuditWriter.write` block in `reopen`.
