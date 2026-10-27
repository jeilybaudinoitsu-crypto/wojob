const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const plans = {
  BUSINESS_GOLD: "STRIPE_PRICE_BUSINESS_GOLD",
  CEO_DIAMOND: "STRIPE_PRICE_CEO_DIAMOND",
} as const;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required function secret: ${name}`);
  return value;
}

function defaultApiKey(legacyName: string, keyCollectionName: string): string {
  const legacyKey = Deno.env.get(legacyName)?.trim();
  if (legacyKey) return legacyKey;

  const keys = JSON.parse(requiredEnv(keyCollectionName)) as Record<string, unknown>;
  const defaultKey = keys.default;
  if (typeof defaultKey !== "string" || !defaultKey) {
    throw new Error(`The default Supabase key is missing from ${keyCollectionName}.`);
  }
  return defaultKey;
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const authorization = request.headers.get("Authorization");
    const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
    if (!accessToken) return jsonResponse({ error: "Authentication required." }, 401);

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const anonKey = defaultApiKey("SUPABASE_ANON_KEY", "SUPABASE_PUBLISHABLE_KEYS");
    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { apikey: anonKey, Authorization: `Bearer ${accessToken}` },
    });
    if (!userResponse.ok) {
      return jsonResponse({ error: "Authentication required." }, 401);
    }

    const user = await userResponse.json();
    if (typeof user.id !== "string") {
      return jsonResponse({ error: "Authentication required." }, 401);
    }

    let input: unknown;
    try {
      input = await request.json();
    } catch {
      return jsonResponse({ error: "Invalid request body." }, 400);
    }
    const plan = (input as { plan?: unknown } | null)?.plan;
    if (typeof plan !== "string" || !Object.hasOwn(plans, plan)) {
      return jsonResponse({ error: "Unsupported subscription plan." }, 400);
    }

    const profileUrl = new URL(`${supabaseUrl}/rest/v1/perfiles`);
    profileUrl.searchParams.set("id", `eq.${user.id}`);
    profileUrl.searchParams.set("select", "id,empresa_id,tipo_usuario,correo");
    const profileResponse = await fetch(profileUrl, {
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${accessToken}`,
      },
    });
    if (!profileResponse.ok) {
      console.error("Could not verify the checkout user's profile.");
      return jsonResponse({ error: "Could not verify account permissions." }, 500);
    }

    const profiles = await profileResponse.json();
    const profile = Array.isArray(profiles) ? profiles[0] : null;
    if (
      !profile ||
      !["admin_principal", "admin_secundario"].includes(profile.tipo_usuario) ||
      typeof profile.empresa_id !== "string" ||
      typeof profile.correo !== "string"
    ) {
      return jsonResponse({ error: "Only company administrators can subscribe." }, 403);
    }

    const companyUrl = new URL(`${supabaseUrl}/rest/v1/empresas`);
    companyUrl.searchParams.set("id", `eq.${profile.empresa_id}`);
    companyUrl.searchParams.set("select", "plan_suscripcion");
    const companyResponse = await fetch(companyUrl, {
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${accessToken}`,
      },
    });
    if (!companyResponse.ok) {
      console.error("Could not verify the company's current subscription.");
      return jsonResponse({ error: "Could not verify the current subscription." }, 500);
    }
    const companies = await companyResponse.json();
    if (!Array.isArray(companies) || companies.length !== 1) {
      return jsonResponse({ error: "Company not found." }, 403);
    }
    if (companies[0].plan_suscripcion !== "FREE") {
      return jsonResponse(
        { error: "The company already has a paid plan. Plan changes are not available yet." },
        409,
      );
    }

    const stripeSecretKey = requiredEnv("STRIPE_SECRET_KEY");
    const priceId = requiredEnv(plans[plan as keyof typeof plans]);
    const successUrlValue = requiredEnv("STRIPE_SUCCESS_URL");
    const cancelUrlValue = requiredEnv("STRIPE_CANCEL_URL");
    const successUrl = new URL(successUrlValue);
    const cancelUrl = new URL(cancelUrlValue);
    if (
      successUrl.protocol !== "wojob:" ||
      successUrl.host !== "payment-success" ||
      successUrl.searchParams.get("session_id") !== "{CHECKOUT_SESSION_ID}" ||
      cancelUrl.protocol !== "wojob:" ||
      cancelUrl.host !== "payment-cancelled"
    ) {
      throw new Error("Stripe return URLs must use the configured WoJob deep links.");
    }
    const form = new URLSearchParams({
      mode: "subscription",
      success_url: successUrlValue,
      cancel_url: cancelUrlValue,
      client_reference_id: profile.empresa_id,
      customer_email: profile.correo,
      "line_items[0][price]": priceId,
      "line_items[0][quantity]": "1",
      "metadata[empresa_id]": profile.empresa_id,
      "metadata[plan]": plan,
      "subscription_data[metadata][empresa_id]": profile.empresa_id,
      "subscription_data[metadata][plan]": plan,
    });
    const stripeResponse = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form,
    });
    const session = await stripeResponse.json();
    if (!stripeResponse.ok || typeof session.url !== "string") {
      console.error("Stripe failed to create a Checkout Session.");
      return jsonResponse({ error: "Stripe could not start the checkout." }, 502);
    }

    return jsonResponse({ url: session.url });
  } catch (error) {
    console.error("Checkout session creation failed:", error);
    return jsonResponse({ error: "Could not start the payment. Check function configuration." }, 500);
  }
});
