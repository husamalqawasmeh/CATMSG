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

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return jsonResponse({ ok: true });
    }

    if (url.pathname === "/api/health") {
      return jsonResponse({
        ok: true,
        app: "CatMsg (PurrCord)",
        domain: "cats.can-du-ai.com",
        stack: "Flutter + Firebase + Cloudflare Edge + Durable Objects"
      });
    }

    if (url.pathname === "/api/userdata") {
      if (env.CATMSG_STORE) {
        try {
          const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
          const stub = env.CATMSG_STORE.get(id);
          const doUrl = new URL(request.url);
          doUrl.pathname = "/userdata";
          return await stub.fetch(new Request(doUrl.toString(), request));
        } catch (e) {
          // Fallback to in-memory if DO call fails
        }
      }

      const saveKey = (url.searchParams.get("key") || "abood").toLowerCase().trim();
      if (request.method === "GET") {
        const snapshot = savedUserDataByKey[saveKey] || null;
        return jsonResponse({
          ok: true,
          key: saveKey,
          found: !!snapshot,
          snapshot
        });
      }
      if (request.method === "POST") {
        try {
          const body = await request.json();
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
      if (env.CATMSG_STORE) {
        try {
          const id = env.CATMSG_STORE.idFromName("global-catmsg-store-v1");
          const stub = env.CATMSG_STORE.get(id);
          const doUrl = new URL(request.url);
          doUrl.pathname = "/messages";
          return await stub.fetch(new Request(doUrl.toString(), request));
        } catch (e) {}
      }

      const channelId = url.searchParams.get("channelId") || "chan_general_meows";
      if (request.method === "GET") {
        return jsonResponse({
          ok: true,
          channelId,
          messages: sharedMessagesByChannel[channelId] || []
        });
      }
      if (request.method === "POST") {
        try {
          const body = await request.json();
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
