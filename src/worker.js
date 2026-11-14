/**
 * Cloudflare Worker for CatMsg (cats.can-du-ai.com)
 * Serves the web app assets and provides a live shared edge API for
 * messages, reactions, server sync, and cloud user data saving/restoring.
 */

const sharedMessagesByChannel = {};
const savedUserDataByKey = {};

const jsonResponse = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    }
  });

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
        stack: "Flutter + Firebase + Cloudflare Edge"
      });
    }

    if (url.pathname === "/api/userdata") {
      const saveKey = (url.searchParams.get("key") || "captain_purr").toLowerCase().trim();
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
