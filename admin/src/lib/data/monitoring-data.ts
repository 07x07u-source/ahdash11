import "server-only";

import { createServerSupabaseClient } from "@/lib/supabase/server";

export interface ErrorIssueRow {
  id: string;
  severity: "info" | "warning" | "error" | "critical";
  category: string;
  feature: string;
  title: string;
  message: string;
  stack: string | null;
  appVersion: string;
  buildNumber: string;
  platform: string;
  firstSeen: string;
  lastSeen: string;
  occurrenceCount: number;
  affectedUsers: number;
  status: "open" | "resolved";
  internalNote: string | null;
  occurrences: { id: string; screen: string | null; networkState: string; context: Record<string, unknown>; occurredAt: string }[];
  relatedReports: { id: string; category: string; status: string; description: string | null; createdAt: string }[];
}

export interface ErrorMonitoringData {
  available: boolean;
  generatedAt: string;
  rows: ErrorIssueRow[];
  summary: { today: number; last24h: number; last7d: number; critical: number; open: number; resolved: number; mostAffectedVersion: string | null };
}

export async function getErrorMonitoringData(): Promise<ErrorMonitoringData> {
  const empty: ErrorMonitoringData = { available: false, generatedAt: new Date().toISOString(), rows: [], summary: { today: 0, last24h: 0, last7d: 0, critical: 0, open: 0, resolved: 0, mostAffectedVersion: null } };
  const supabase = await createServerSupabaseClient();
  if (!supabase) return empty;
  const now = Date.now();
  const today = new Date(now); today.setHours(0, 0, 0, 0);

  const [issues, occurrences, reports, todayCount, last24hCount, last7dCount] = await Promise.all([
    supabase.from("app_error_issues").select("id,severity,category,feature,title,sanitized_message,sanitized_stack,app_version,build_number,platform,first_seen,last_seen,occurrence_count,affected_users_count,status,internal_note").order("last_seen", { ascending: false }).limit(200),
    supabase.from("app_error_occurrences").select("id,issue_id,screen,network_state,safe_context,occurred_at").order("occurred_at", { ascending: false }).limit(500),
    supabase.from("user_problem_reports").select("id,linked_issue_id,category,status,description,created_at").not("linked_issue_id", "is", null).order("created_at", { ascending: false }).limit(200),
    supabase.from("app_error_occurrences").select("id", { count: "exact", head: true }).gte("occurred_at", today.toISOString()),
    supabase.from("app_error_occurrences").select("id", { count: "exact", head: true }).gte("occurred_at", new Date(now - 86_400_000).toISOString()),
    supabase.from("app_error_occurrences").select("id", { count: "exact", head: true }).gte("occurred_at", new Date(now - 604_800_000).toISOString()),
  ]);
  if (issues.error || occurrences.error || reports.error || todayCount.error || last24hCount.error || last7dCount.error) return empty;
  const rows: ErrorIssueRow[] = (issues.data ?? []).map((row) => ({
    id: String(row.id), severity: row.severity as ErrorIssueRow["severity"], category: String(row.category), feature: String(row.feature),
    title: String(row.title), message: String(row.sanitized_message), stack: row.sanitized_stack ? String(row.sanitized_stack) : null,
    appVersion: String(row.app_version), buildNumber: String(row.build_number), platform: String(row.platform), firstSeen: String(row.first_seen), lastSeen: String(row.last_seen),
    occurrenceCount: Number(row.occurrence_count), affectedUsers: Number(row.affected_users_count), status: row.status as ErrorIssueRow["status"], internalNote: row.internal_note ? String(row.internal_note) : null,
    occurrences: (occurrences.data ?? []).filter((entry) => entry.issue_id === row.id).slice(0, 12).map((entry) => ({ id: String(entry.id), screen: entry.screen ? String(entry.screen) : null, networkState: String(entry.network_state), context: entry.safe_context && typeof entry.safe_context === "object" ? entry.safe_context as Record<string, unknown> : {}, occurredAt: String(entry.occurred_at) })),
    relatedReports: (reports.data ?? []).filter((entry) => entry.linked_issue_id === row.id).map((entry) => ({ id: String(entry.id), category: String(entry.category), status: String(entry.status), description: entry.description ? String(entry.description) : null, createdAt: String(entry.created_at) })),
  }));
  const versions = new Map<string, number>();
  for (const row of rows) versions.set(row.appVersion, (versions.get(row.appVersion) ?? 0) + row.occurrenceCount);
  const mostAffectedVersion = [...versions.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;
  return { available: true, generatedAt: new Date(now).toISOString(), rows, summary: {
    today: todayCount.count ?? 0,
    last24h: last24hCount.count ?? 0,
    last7d: last7dCount.count ?? 0,
    critical: rows.filter((row) => row.severity === "critical" && row.status === "open").length,
    open: rows.filter((row) => row.status === "open").length,
    resolved: rows.filter((row) => row.status === "resolved").length,
    mostAffectedVersion,
  } };
}

export interface UserProblemReportRow {
  id: string; category: string; description: string | null; screen: string | null; appVersion: string; buildNumber: string;
  platform: string; status: "new" | "in_review" | "resolved" | "rejected"; linkedIssueId: string | null; adminNote: string | null; createdAt: string;
}

export async function getUserProblemReports(): Promise<{ available: boolean; rows: UserProblemReportRow[] }> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { available: false, rows: [] };
  const { data, error } = await supabase.from("user_problem_reports").select("id,category,description,screen,app_version,build_number,platform,status,linked_issue_id,admin_note,created_at").order("created_at", { ascending: false }).limit(200);
  if (error) return { available: false, rows: [] };
  return { available: true, rows: (data ?? []).map((row) => ({
    id: String(row.id), category: String(row.category), description: row.description ? String(row.description) : null, screen: row.screen ? String(row.screen) : null,
    appVersion: String(row.app_version), buildNumber: String(row.build_number), platform: String(row.platform), status: row.status as UserProblemReportRow["status"],
    linkedIssueId: row.linked_issue_id ? String(row.linked_issue_id) : null, adminNote: row.admin_note ? String(row.admin_note) : null, createdAt: String(row.created_at),
  })) };
}

export interface SystemHealthData {
  connected: boolean;
  monitoringAvailable: boolean;
  contentRpcAvailable: boolean;
  publishedContentCount: number;
  lastContentPublish: string | null;
  lastNotificationAttempt: string | null;
  notificationMonitoringAvailable: boolean;
  notificationFailures24h: number;
  errors24h: number;
  activeVersions: { version: string; devices: number }[];
}

export async function getSystemHealthData(): Promise<SystemHealthData> {
  const fallback: SystemHealthData = { connected: false, monitoringAvailable: false, contentRpcAvailable: false, publishedContentCount: 0, lastContentPublish: null, lastNotificationAttempt: null, notificationMonitoringAvailable: false, notificationFailures24h: 0, errors24h: 0, activeVersions: [] };
  const supabase = await createServerSupabaseClient();
  if (!supabase) return fallback;
  const since = new Date(Date.now() - 86_400_000).toISOString();
  const [connection, content, deliveries, failedDeliveries, issues, devices] = await Promise.all([
    supabase.from("categories").select("id", { count: "exact", head: true }),
    supabase.rpc("get_published_app_content"),
    supabase.from("notification_deliveries").select("attempted_at").order("attempted_at", { ascending: false }).limit(1),
    supabase.from("notification_deliveries").select("id", { count: "exact", head: true }).eq("status", "failed").gte("attempted_at", since),
    supabase.from("app_error_issues").select("occurrence_count,last_seen").gte("last_seen", since),
    supabase.from("device_tokens").select("app_version").eq("is_active", true),
  ]);
  const versionCounts = new Map<string, number>();
  for (const row of devices.data ?? []) { const version = String(row.app_version ?? "غير معروف"); versionCounts.set(version, (versionCounts.get(version) ?? 0) + 1); }
  return {
    connected: !connection.error,
    monitoringAvailable: !issues.error,
    contentRpcAvailable: !content.error,
    publishedContentCount: content.data?.length ?? 0,
    lastContentPublish: !content.error && content.data?.length ? String([...content.data].sort((a, b) => String(b.published_at).localeCompare(String(a.published_at)))[0].published_at ?? "") || null : null,
    lastNotificationAttempt: deliveries.data?.[0]?.attempted_at ? String(deliveries.data[0].attempted_at) : null,
    notificationMonitoringAvailable: !deliveries.error && !failedDeliveries.error,
    notificationFailures24h: failedDeliveries.count ?? 0,
    errors24h: issues.error ? 0 : (issues.data ?? []).reduce((sum, row) => sum + Number(row.occurrence_count ?? 0), 0),
    activeVersions: [...versionCounts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8).map(([version, count]) => ({ version, devices: count })),
  };
}

export interface AuditRow { id: string; actorId: string | null; actorName: string | null; action: string; entityType: string; entityId: string | null; createdAt: string }
export async function getAuditRows(): Promise<{ available: boolean; rows: AuditRow[] }> {
  const supabase = await createServerSupabaseClient();
  if (!supabase) return { available: false, rows: [] };
  const { data, error } = await supabase.from("audit_logs").select("id,actor_user_id,action,entity_type,entity_id,created_at").order("created_at", { ascending: false }).limit(150);
  if (error) return { available: false, rows: [] };
  const actorIds = [...new Set((data ?? []).map((row) => row.actor_user_id).filter(Boolean))] as string[];
  const profiles = actorIds.length ? await supabase.from("profiles").select("id,display_name,username").in("id", actorIds) : { data: [], error: null };
  const actorNames = new Map((profiles.data ?? []).map((row) => [String(row.id), String(row.display_name || row.username || "")]));
  return { available: true, rows: (data ?? []).map((row) => {
    const actorId = row.actor_user_id ? String(row.actor_user_id) : null;
    return { id: String(row.id), actorId, actorName: actorId ? actorNames.get(actorId) || null : null, action: String(row.action), entityType: String(row.entity_type), entityId: row.entity_id ? String(row.entity_id) : null, createdAt: String(row.created_at) };
  }) };
}
