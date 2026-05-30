import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (_req) => {
  try {
    // Busca cotação do dólar e euro na AwesomeAPI
    const response = await fetch("https://economia.awesomeapi.com.br/last/USD-BRL,EUR-BRL");
    const data = await response.json();

    const dolar = parseFloat(data.USDBRL.bid);
    const euro = parseFloat(data.EURBRL.bid);

    return new Response(
      JSON.stringify({ dolar, euro }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Erro ao buscar cotação em tempo real" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});