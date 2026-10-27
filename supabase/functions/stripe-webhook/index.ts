const encoder = new TextEncoder();
const validPlans = new Set(["BUSINESS_GOLD", "CEO_DIAMOND"]);

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required function secret: ${name}`);
  return value;
}

function defaultSupabaseSecretKey(): string {
  const legacyKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (legacyKey) return legacyKey;

  const keys = JSON.parse(requiredEnv("SUPABASE_SECRET_KEYS")) as Record<
    string,
    unknown
  >;
  const defaultKey = keys.default;
  if (typeof defaultKey !== "string" || !defaultKey) {
    throw new Error("The default Supabase secret key is missing.");
  }
  return defaultKey;
}

function hexToBytes(hex: string): Uint8Array | null {
  if (!/^[\da-f]{64}$/i.test(hex)) return null;
  const bytes = new Uint8Array(32);
  for (let index = 0; index < bytes.length; index += 1) {
    bytes[index] = Number.parseInt(hex.slice(index * 2, index * 2 + 2), 16);
  }
  return bytes;
}

async function hasValidStripeSignature(
  payload: string,
  signatureHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader) return false;

  const parts = signatureHeader.split(",");
  const timestamp = parts.find((part) => part.startsWith("t="))?.slice(2);
  const signatures = parts
    .filter((part) => part.startsWith("v1="))
    .map((part) => hexToBytes(part.slice(3)))
    .filter((value): value is Uint8Array => value !== null);
  if (!timestamp || !/^\d+$/.test(timestamp) || signatures.length === 0) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const signedPayload = encoder.encode(`${timestamp}.${payload}`);
  for (const signature of signatures) {
    if (await crypto.subtle.verify("HMAC", key, signature, signedPayload)) return true;
  }
  return false;
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const payload = await request.text();
    const isValid = await hasValidStripeSignature(
      payload,
      request.headers.get("stripe-signature"),
      requiredEnv("STRIPE_WEBHOOK_SECRET"),
    );
    if (!isValid) return jsonResponse({ error: "Invalid Stripe signature." }, 400);

    let event: {
      type?: string;
      data?: {
        object?: {
          object?: string;
          id?: string;
          status?: string;
          metadata?: Record<string, string>;
        };
      };
    };
    try {
      event = JSON.parse(payload);
    } catch {
      return jsonResponse({ error: "Invalid event body." }, 400);
    }

    if (
      !["customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"]
        .includes(event.type ?? "")
    ) {
      return jsonResponse({ received: true });
    }

    const subscription = event.data?.object;
    if (subscription?.object !== "subscription" || typeof subscription.id !== "string") {
      return jsonResponse({ received: true, ignored: true });
    }

    const stripeSecretKey = requiredEnv("STRIPE_SECRET_KEY");
    const currentSubscriptionResponse = await fetch(
      `https://api.stripe.com/v1/subscriptions/${encodeURIComponent(subscription.id)}`,
      { headers: { Authorization: `Bearer ${stripeSecretKey}` } },
    );
    if (!currentSubscriptionResponse.ok) {
      console.error("Could not retrieve the current Stripe subscription.");
      return jsonResponse({ error: "Could not verify the current subscription." }, 502);
    }
    const currentSubscription = await currentSubscriptionResponse.json();
    const metadata = currentSubscription.metadata as Record<string, string> | undefined;
    const companyId = metadata?.empresa_id;
    const plan = metadata?.plan;
    if (
      currentSubscription.object !== "subscription" ||
      !companyId ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(companyId) ||
      !plan ||
      !validPlans.has(plan)
    ) {
      return jsonResponse({ received: true, ignored: true });
    }

    const isActive = ["active", "trialing"].includes(currentSubscription.status ?? "") &&
      event.type !== "customer.subscription.deleted";
    const nextPlan = isActive ? plan : "FREE";
    const employeeLimit = nextPlan === "BUSINESS_GOLD" ? 250 : nextPlan === "FREE" ? 10 : null;
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const serviceRoleKey = defaultSupabaseSecretKey();
    const companyUrl = new URL(`${supabaseUrl}/rest/v1/empresas`);
    companyUrl.searchParams.set("id", `eq.${companyId}`);
    const updateResponse = await fetch(companyUrl, {
      method: "PATCH",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
        Prefer: "return=representation",
      },
      body: JSON.stringify({
        plan_suscripcion: nextPlan,
        limite_empleados: employeeLimit,
      }),
    });
    if (!updateResponse.ok) {
      console.error("Could not update the subscription after Stripe confirmation.");
      return jsonResponse({ error: "Could not update the company subscription." }, 500);
    }

    const updatedCompanies = await updateResponse.json();
    if (!Array.isArray(updatedCompanies) || updatedCompanies.length !== 1) {
      console.error("Stripe subscription references a company that does not exist.");
      return jsonResponse({ error: "Company not found." }, 500);
    }

    return jsonResponse({ received: true });
  } catch (error) {
    console.error("Stripe webhook processing failed:", error);
    return jsonResponse({ error: "Could not process the Stripe event." }, 500);
  }
});
