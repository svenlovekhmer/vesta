class GmailAnalysisService
  ENDPOINT = "https://models.inference.ai.azure.com/chat/completions"
  MODEL    = "gpt-4o-mini"

  def initialize(messages, client_email:, provider_name:)
    @messages      = messages
    @client_email  = client_email
    @provider_name = provider_name
  end

  # Streams synthesis tokens — yields each text chunk as it arrives
  def stream_synthesis(&block)
    buffer = ""

    Faraday.post(ENDPOINT) do |req|
      req.headers["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}"
      req.headers["Content-Type"]  = "application/json"
      req.body = JSON.generate(streaming_payload)
      req.options.on_data = proc do |chunk, _size|
        buffer += chunk
        while (idx = buffer.index("\n\n"))
          event  = buffer[0, idx]
          buffer = buffer[(idx + 2)..]
          event.each_line do |line|
            line = line.chomp
            next unless line.start_with?("data: ")
            json_str = line[6..]
            next if json_str.strip == "[DONE]"
            content = JSON.parse(json_str).dig("choices", 0, "delta", "content")
            block.call(content) if content.present?
          rescue JSON::ParseError
            nil
          end
        end
      end
    end
  end

  # Non-streaming call — returns { "decided" => [...], "pending" => [...] }
  def analyze_decisions
    response = Faraday.post(ENDPOINT) do |req|
      req.headers["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}"
      req.headers["Content-Type"]  = "application/json"
      req.body = JSON.generate(decisions_payload)
    end
    raw = JSON.parse(response.body).dig("choices", 0, "message", "content")
    JSON.parse(raw)
  end

  private

  def streaming_payload
    {
      model: MODEL,
      stream: true,
      messages: [
        { role: "system", content: synthesis_prompt },
        { role: "user",   content: emails_text }
      ]
    }
  end

  def decisions_payload
    {
      model: MODEL,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: decisions_prompt },
        { role: "user",   content: emails_text }
      ]
    }
  end

  def synthesis_prompt
    <<~PROMPT
      Tu es un assistant expert pour des professionnels de l'amenagement interieur.
      Analyse les echanges emails entre le professionnel "#{@provider_name}" et son client (#{@client_email}).
      Ecris uniquement une synthese concise en 2-3 phrases en francais.
      Texte brut uniquement, sans JSON ni formatage markdown.
    PROMPT
  end

  def decisions_prompt
    <<~PROMPT
      Tu es un assistant expert pour des professionnels de l'amenagement interieur.
      Analyse les echanges emails entre le professionnel "#{@provider_name}" et son client (#{@client_email}).
      Retourne uniquement un objet JSON valide avec exactement ces deux cles :
      - "decided" : tableau d'objets {text, owner} listant tous les points valides/actes explicitement dans les echanges
      - "pending" : tableau d'objets {text, owner} listant tous les points en attente ou actions a realiser

      owner vaut "client", "provider" ou "third_party".
      N'invente pas de date, de responsable ou de decision non presente dans les emails.
      Si aucun point dans une categorie, retourne [].
      Ne retourne que le JSON, sans texte supplementaire.
    PROMPT
  end

  def emails_text
    @messages.map do |m|
      "---\nDe: #{m[:from]}\nDate: #{m[:date]}\nObjet: #{m[:subject]}\n\n#{m[:body]}"
    end.join("\n\n")
  end
end
