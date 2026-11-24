/**
 * Cloudflare Worker + Persistent Durable Object for CatMsg (cats.can-du-ai.com)
 * Serves the web app assets and provides permanent global cross-browser storage
 * for user accounts, passwords, progress snapshots, and channel messages.
 */

const sharedMessagesByChannel = {};
const savedUserDataByKey = {};

const jsonResponse = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store, no-cache, must-revalidate",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    }
  });

export class CatMsgStorageDO {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/userdata") {
      const saveKey = (url.searchParams.get("key") || "abood").toLowerCase().trim();

      if (request.method === "GET") {
        let snapshot = await this.ctx.storage.get(`userdata:${saveKey}`);
        if (!snapshot && saveKey !== "__accounts_registry__") {
          const registry = (await this.ctx.storage.get("userdata:__accounts_registry__")) || {};
          if (registry[saveKey] && registry[saveKey].snapshot) {
            snapshot = registry[saveKey].snapshot;
          }
        }
        return jsonResponse({
          ok: true,
          key: saveKey,
          found: !!snapshot,
          snapshot: snapshot || null
        });
      }

      if (request.method === "POST") {
        try {
          const body = await request.json();
          const nowIso = new Date().toISOString();

          if (saveKey === "__promo_codes_registry__") {
            await this.ctx.storage.put("userdata:__promo_codes_registry__", body || {});
            return jsonResponse({
              ok: true,
              key: saveKey,
              savedAt: nowIso
            });
          } else if (saveKey === "__accounts_registry__") {
            const existingRegistry = (await this.ctx.storage.get("userdata:__accounts_registry__")) || {};
            const mergedRegistry = { ...existingRegistry };

            for (const [rawUser, incomingAcc] of Object.entries(body || {})) {
              if (!incomingAcc || typeof incomingAcc !== "object") continue;
              const uKey = rawUser.toLowerCase().trim();
              const prevAcc = mergedRegistry[uKey] || {};
              const resolvedPassword = incomingAcc.password || prevAcc.password || "";
              mergedRegistry[uKey] = {
                ...prevAcc,
                ...incomingAcc,
                username: uKey,
                password: resolvedPassword,
                savedAtServer: nowIso
              };
              if (incomingAcc.snapshot) {
                await this.ctx.storage.put(`userdata:${uKey}`, {
                  ...incomingAcc.snapshot,
                  savedAtServer: nowIso
                });
              }
            }

            await this.ctx.storage.put("userdata:__accounts_registry__", mergedRegistry);
            return jsonResponse({
              ok: true,
              key: saveKey,
              savedAt: nowIso
            });
          } else {
            const record = {
              ...body,
              savedAtServer: nowIso
            };
            await this.ctx.storage.put(`userdata:${saveKey}`, record);

            // Also keep __accounts_registry__ snapshot in sync for cross-browser login
            const existingRegistry = (await this.ctx.storage.get("userdata:__accounts_registry__")) || {};
            const prevAcc = existingRegistry[saveKey] || {};
            existingRegistry[saveKey] = {
              ...prevAcc,
              username: saveKey,
              displayName: (body.currentUser && body.currentUser.displayName) || prevAcc.displayName || saveKey,
              avatarEmoji: (body.currentUser && body.currentUser.avatarEmoji) || prevAcc.avatarEmoji || "🐱",
              isOwner: !!(body.currentUser && body.currentUser.isOwner) || !!prevAcc.isOwner,
              password: body.accountPassword || prevAcc.password || "",
              googleEmail: (body.currentUser && body.currentUser.googleEmail) || prevAcc.googleEmail || "",
              lastSavedAt: body.savedAt || nowIso,
              savedAtServer: nowIso,
              snapshot: record
            };
            await this.ctx.storage.put("userdata:__accounts_registry__", existingRegistry);

            return jsonResponse({
              ok: true,
              key: saveKey,
              savedAt: nowIso
            });
          }
        } catch (err) {
          return jsonResponse({ ok: false, error: String(err) }, 400);
        }
      }
    }

    if (url.pathname === "/messages") {
      const channelId = url.searchParams.get("channelId") || "chan_general_meows";
      if (request.method === "GET") {
        const list = (await this.ctx.storage.get(`messages:${channelId}`)) || [];
        return jsonResponse({
          ok: true,
          channelId,
          messages: list
        });
      }
      if (request.method === "POST") {
        try {
          const body = await request.json();
          const list = (await this.ctx.storage.get(`messages:${channelId}`)) || [];
          list.push(body);
          if (list.length > 100) list.shift();
          await this.ctx.storage.put(`messages:${channelId}`, list);
          return jsonResponse({ ok: true, message: body });
        } catch (err) {
          return jsonResponse({ ok: false, error: String(err) }, 400);
        }
      }
    }

    return jsonResponse({ ok: false, error: "Not found" }, 404);
  }
}

async function callSupabaseStorage(env, action, queryParamName, queryParamVal, method = "GET", bodyText = null) {
  if (!env.SUPABASE_EDGE_URL || !env.CATMSG_SUPABASE_TOKEN) return null;
  try {
    const targetUrl = `${env.SUPABASE_EDGE_URL}?action=${encodeURIComponent(action)}&${encodeURIComponent(queryParamName)}=${encodeURIComponent(queryParamVal)}`;
    const headers = {
      "x-catmsg-key": env.CATMSG_SUPABASE_TOKEN
    };
    if (bodyText !== null) {
      headers["Content-Type"] = "application/json";
    }
    const res = await fetch(targetUrl, {
      method,
      headers,
      body: bodyText
    });
    if (!res.ok) return null;
    return await res.json();
  } catch (e) {
    return null;
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return jsonResponse({ ok: true });
    }

    if (url.pathname === "/api/health") {
      const hasSupabase = !!(env.SUPABASE_EDGE_URL && env.CATMSG_SUPABASE_TOKEN);
      return jsonResponse({
        ok: true,
        app: "CatMsg (PurrCord)",
        domain: "cats.can-du-ai.com",
        storage: hasSupabase ? "Supabase Postgres + Cloudflare Durable Objects" : "Cloudflare Durable Objects"
      });
    }

    if (url.pathname === "/api/userdata") {
      const saveKey = (url.searchParams.get("key") || "abood").toLowerCase().trim();

      if (request.method === "GET") {
        const supaData = await callSupabaseStorage(env, "userdata", "key", saveKey, "GET");
        if (supaData && supaData.found) {
          return jsonResponse(supaData);
        }

        if (env.CATMSG_STORE) {
          try {
            const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
            const stub = env.CATMSG_STORE.get(id);
            const doUrl = new URL(request.url);
            doUrl.pathname = "/userdata";
            const doRes = await stub.fetch(new Request(doUrl.toString(), { method: "GET" }));
            const doJson = await doRes.json();
            if (doJson && doJson.found && doJson.snapshot) {
              // Automatically backfill legacy Durable Object snapshot into Supabase Postgres
              if (env.SUPABASE_EDGE_URL && env.CATMSG_SUPABASE_TOKEN) {
                const backfillPromise = callSupabaseStorage(env, "userdata", "key", saveKey, "POST", JSON.stringify(doJson.snapshot));
                if (ctx && typeof ctx.waitUntil === "function") {
                  ctx.waitUntil(backfillPromise);
                }
              }
              return jsonResponse(doJson);
            }
            if (supaData) return jsonResponse(supaData);
            return jsonResponse(doJson);
          } catch (e) {}
        }

        if (supaData) return jsonResponse(supaData);
        const snapshot = savedUserDataByKey[saveKey] || null;
        return jsonResponse({ ok: true, key: saveKey, found: !!snapshot, snapshot });
      }

      if (request.method === "POST") {
        try {
          const bodyText = await request.text();
          const supaRes = await callSupabaseStorage(env, "userdata", "key", saveKey, "POST", bodyText);

          let doJson = null;
          if (env.CATMSG_STORE) {
            try {
              const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
              const stub = env.CATMSG_STORE.get(id);
              const doUrl = new URL(request.url);
              doUrl.pathname = "/userdata";
              const doRes = await stub.fetch(new Request(doUrl.toString(), {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: bodyText
              }));
              doJson = await doRes.json();
            } catch (e) {}
          }

          if (supaRes && supaRes.ok) return jsonResponse(supaRes);
          if (doJson && doJson.ok) return jsonResponse(doJson);

          const body = JSON.parse(bodyText);
          savedUserDataByKey[saveKey] = {
            ...body,
            savedAtServer: new Date().toISOString()
          };
          return jsonResponse({
            ok: true,
            key: saveKey,
            savedAt: savedUserDataByKey[saveKey].savedAtServer
          });
        } catch (err) {
          return jsonResponse({ ok: false, error: String(err) }, 400);
        }
      }
    }

    if (url.pathname === "/api/messages") {
      const channelId = url.searchParams.get("channelId") || "chan_general_meows";

      if (request.method === "GET") {
        const supaMsgs = await callSupabaseStorage(env, "messages", "channelId", channelId, "GET");
        if (supaMsgs && supaMsgs.ok && Array.isArray(supaMsgs.messages) && supaMsgs.messages.length > 0) {
          return jsonResponse(supaMsgs);
        }

        if (env.CATMSG_STORE) {
          try {
            const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
            const stub = env.CATMSG_STORE.get(id);
            const doUrl = new URL(request.url);
            doUrl.pathname = "/messages";
            const doRes = await stub.fetch(new Request(doUrl.toString(), { method: "GET" }));
            const doJson = await doRes.json();
            if (doJson && Array.isArray(doJson.messages) && doJson.messages.length > 0) {
              return jsonResponse(doJson);
            }
          } catch (e) {}
        }

        if (supaMsgs && supaMsgs.ok) return jsonResponse(supaMsgs);
        return jsonResponse({
          ok: true,
          channelId,
          messages: sharedMessagesByChannel[channelId] || []
        });
      }

      if (request.method === "POST") {
        try {
          const bodyText = await request.text();
          const supaRes = await callSupabaseStorage(env, "messages", "channelId", channelId, "POST", bodyText);

          let doJson = null;
          if (env.CATMSG_STORE) {
            try {
              const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
              const stub = env.CATMSG_STORE.get(id);
              const doUrl = new URL(request.url);
              doUrl.pathname = "/messages";
              const doRes = await stub.fetch(new Request(doUrl.toString(), {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: bodyText
              }));
              doJson = await doRes.json();
            } catch (e) {}
          }

          if (supaRes && supaRes.ok) return jsonResponse(supaRes);
          if (doJson && doJson.ok) return jsonResponse(doJson);

          const body = JSON.parse(bodyText);
          if (!sharedMessagesByChannel[channelId]) {
            sharedMessagesByChannel[channelId] = [];
          }
          sharedMessagesByChannel[channelId].push(body);
          if (sharedMessagesByChannel[channelId].length > 100) {
            sharedMessagesByChannel[channelId].shift();
          }
          return jsonResponse({ ok: true, message: body });
        } catch (err) {
          return jsonResponse({ ok: false, error: String(err) }, 400);
        }
      }
    }

    return env.ASSETS.fetch(request);
  }
};
