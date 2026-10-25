/**
 * The browser-tab title suffix, from the `PI_WEB_TITLE_SUFFIX` environment
 * variable. Exists so the same question a client cannot otherwise ask —
 * "which node is this tab talking to?" — has a server-side answer: several
 * PAI nodes are often open side by side, and their tab titles would
 * otherwise be identical.
 *
 * Read at request time (no rebuild needed when it changes); empty when
 * unset, and the client keeps the stock `会话名 - PAI` title.
 */
export const dynamic = "force-dynamic";

export async function GET(): Promise<Response> {
  const suffix = (process.env.PI_WEB_TITLE_SUFFIX ?? "").trim();
  return Response.json(
    { suffix },
    { headers: { "Cache-Control": "no-store" } },
  );
}
