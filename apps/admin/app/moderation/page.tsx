export default function ModerationPage() {
  const modules = [
    ["Report queue", "GET /v1/admin/moderation/reports", "Submitted reports with category, context, reporter and reported-user IDs."],
    ["Review workflow", "PATCH /v1/admin/moderation/reports/:reportId", "Triage, investigate, action or dismiss; every status change is audited."],
    ["User sanctions", "POST /v1/admin/moderation/sanctions", "Warnings and timed suspensions; permanent ban reserved for superadmins."],
    ["Audit trail", "moderation_audit_log", "Actor, target, report/sanction reference and action metadata."]
  ];
  return <main className="admin">
    <header><strong>VibeMingle</strong><span>TRUST & SAFETY · MODERATION</span></header>
    <section>
      <p className="tag">RESTRICTED · RBAC REQUIRED</p><h1>Moderation Console</h1>
      <p>Backend moderation endpoints are protected by enabled moderator/admin/superadmin records. This page is a UI scaffold; it does not display live user reports until the admin identity, MFA and API session integration are configured.</p>
      <div className="notice">Setup gate: review and apply migration 0015, then provision the first superadmin out-of-band. Do not seed privileged roles from client input.</div>
      <div className="modules">{modules.map(([name,endpoint,detail])=><article key={name}><h2>{name}</h2><code>{endpoint}</code><p>{detail}</p></article>)}</div>
      <p className="footnote">No reports or personal data are fetched on this scaffold. All privileged actions must be server-authorized and audit logged.</p>
    </section>
  </main>;
}
