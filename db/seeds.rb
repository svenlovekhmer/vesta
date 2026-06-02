puts "Cleaning database..."
DecisionLog.destroy_all
Document.destroy_all
Step.destroy_all
Mission.destroy_all
Client.destroy_all
StepTemplateItem.destroy_all
StepTemplate.destroy_all
Profile.destroy_all
User.destroy_all
MissionStatus.destroy_all
StepStatus.destroy_all

puts "Creating statuses..."

mission_statuses = {
  en_attente:  MissionStatus.create!(title: "En attente"),
  en_cours:    MissionStatus.create!(title: "En cours"),
  en_revision: MissionStatus.create!(title: "En révision"),
  terminee:    MissionStatus.create!(title: "Terminée")
}

step_statuses = {
  a_faire:   StepStatus.create!(title: "À faire"),
  en_cours:  StepStatus.create!(title: "En cours"),
  validee:   StepStatus.create!(title: "Validée"),
  bloquee:   StepStatus.create!(title: "Bloquée")
}

puts "Creating user..."

user = User.create!(
  email: "sven@vesta.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "Creating profile..."

Profile.create!(
  user: user,
  first_name: "Sven",
  last_name: "Dupont",
  profession: "Architecte d'intérieur",
  logo_url: nil
)

puts "Creating step template..."

template = StepTemplate.create!(
  user: user,
  name: "Projet rénovation standard",
  description: "Template pour projets de rénovation résidentielle",
  is_default: "false"
)

default_template = StepTemplate.create!(
  user: user,
  name: "Modèle par défaut",
  description: "Template standard pour les missions d'accompagnement",
  is_default: "true"
)

[
  { title: "Brief reçu",           position: "1" },
  { title: "Visite réalisée",      position: "2" },
  { title: "Devis validé",         position: "3" },
  { title: "Réalisation en cours", position: "4" },
  { title: "Livraison",            position: "5" },
  { title: "Mission terminée",     position: "6" }
].each { |item| StepTemplateItem.create!(step_template: default_template, **item) }

[
  { title: "Brief client",         description: "Recueil des besoins et attentes du client",        position: "1" },
  { title: "Étude de faisabilité", description: "Analyse technique et budgétaire du projet",        position: "2" },
  { title: "Plans & rendus 3D",    description: "Conception des plans et visualisations 3D",        position: "3" },
  { title: "Validation client",    description: "Présentation et validation par le client",          position: "4" },
  { title: "Appel d'offres",       description: "Sélection et négociation avec les artisans",       position: "5" },
  { title: "Suivi de chantier",    description: "Coordination et contrôle de l'avancement",        position: "6" },
  { title: "Réception des travaux",description: "Vérification finale et remise des clés",          position: "7" }
].each do |item|
  StepTemplateItem.create!(step_template: template, **item)
end

puts "Creating clients..."

clients = [
  { first_name: "Marie",    last_name: "Laurent",  email: "marie.laurent@email.com", phone_number: "0601020304" },
  { first_name: "Thomas",   last_name: "Moreau",   email: "thomas.moreau@email.com", phone_number: "0601020305" },
  { first_name: "Isabelle", last_name: "Petit",    email: "isabelle.petit@email.com", phone_number: "0601020306" },
  { first_name: "Nicolas",  last_name: "Bernard",  email: "nicolas.bernard@email.com", phone_number: "0601020307" }
].map { |attrs| Client.create!(user_id: user.id, **attrs) }

puts "Creating missions..."

missions_data = [
  {
    title: "Rénovation appartement Haussman – Marie Laurent",
    client: clients[0],
    status: mission_statuses[:en_cours],
    steps: [
      { title: "Brief client",         description: "Premier rendez-vous de cadrage",                        position: 1, status: :validee,  validate_at: 3.weeks.ago },
      { title: "Étude de faisabilité", description: "Analyse de l'espace et contraintes structurelles",      position: 2, status: :validee,  validate_at: 2.weeks.ago },
      { title: "Plans & rendus 3D",    description: "Conception du plan de l'appartement 85m²",              position: 3, status: :en_cours, validate_at: nil },
      { title: "Validation client",    description: "Réunion de présentation des plans",                     position: 4, status: :a_faire,  validate_at: nil },
      { title: "Appel d'offres",       description: "Consultation des artisans partenaires",                 position: 5, status: :a_faire,  validate_at: nil }
    ],
    decision_logs: [
      { title: "Délai menuiserie – 8 semaines",   description: "Délai artisan menuisier confirmé à 8 semaines.",        status: "pending", owner_type: "provider" },
      { title: "Budget travaux V3 – 45 000 €",    description: "Budget recadré à 45 000€ suite à l'étude de faisabilité.", status: "pending", owner_type: "client" },
      { title: "Conservation des moulures",        description: "Client souhaite conserver les moulures d'origine.",       status: "decided", owner_type: "client", decided_by: "Marie Laurent", decided_at: 3.weeks.ago }
    ]
  },
  {
    title: "Aménagement bureau à domicile – Thomas Moreau",
    client: clients[1],
    status: mission_statuses[:en_attente],
    steps: [
      { title: "Brief client",         description: "Appel de découverte du projet",                         position: 1, status: :validee,  validate_at: 1.week.ago },
      { title: "Étude de faisabilité", description: "Visite du domicile et prise de mesures",               position: 2, status: :a_faire,  validate_at: nil },
      { title: "Plans & rendus 3D",    description: "Proposition d'aménagement de la pièce 20m²",           position: 3, status: :a_faire,  validate_at: nil }
    ],
    decision_logs: [
      { title: "Choix revêtement sol",       description: "Parquet ou béton ciré ?",                  status: "pending", owner_type: "provider" },
      { title: "Validation devis mobilier",  description: "Devis mobilier bureau à valider.",          status: "pending", owner_type: "client" },
      { title: "Périmètre une pièce",        description: "Projet limité à une seule pièce, 20m².",   status: "decided", owner_type: "client", decided_by: "Thomas Moreau", decided_at: 1.week.ago }
    ]
  },
  {
    title: "Rénovation complète maison – Isabelle Petit",
    client: clients[2],
    status: mission_statuses[:en_revision],
    steps: [
      { title: "Brief client",         description: "Réunion initiale avec la famille",                      position: 1, status: :validee,  validate_at: 2.months.ago },
      { title: "Étude de faisabilité", description: "Étude structurelle et diagnostic énergétique",         position: 2, status: :validee,  validate_at: 6.weeks.ago },
      { title: "Plans & rendus 3D",    description: "Plans complets maison 160m² sur 2 niveaux",            position: 3, status: :validee,  validate_at: 1.month.ago },
      { title: "Validation client",    description: "Ajustements demandés sur la cuisine et la salle de bain", position: 4, status: :en_cours, validate_at: nil },
      { title: "Appel d'offres",       description: "En attente de validation avant envoi aux artisans",    position: 5, status: :bloquee,  validate_at: nil },
      { title: "Suivi de chantier",    description: "Démarrage prévu après validation",                     position: 6, status: :a_faire,  validate_at: nil },
      { title: "Réception des travaux",description: "Remise des clés prévue en fin d'année",               position: 7, status: :a_faire,  validate_at: nil }
    ],
    decision_logs: [
      { title: "Révision plan cuisine",  description: "Révision demandée par le client.",                          status: "pending", owner_type: "client" },
      { title: "Extension urbanisme",    description: "Extension de 20m² validée par les services d'urbanisme.",   status: "decided", owner_type: "provider", decided_by: "Sven Dupont",     decided_at: 6.weeks.ago },
      { title: "Choix matériaux",        description: "Parquet chêne et carrelage grès pour les pièces humides.",  status: "decided", owner_type: "client",   decided_by: "Isabelle Petit",  decided_at: 1.month.ago }
    ]
  },
  {
    title: "Décoration salon & salle à manger – Nicolas Bernard",
    client: clients[3],
    status: mission_statuses[:terminee],
    steps: [
      { title: "Brief client",         description: "Identification du style souhaité",                     position: 1, status: :validee, validate_at: 3.months.ago },
      { title: "Étude de faisabilité", description: "État des lieux et budget déco",                        position: 2, status: :validee, validate_at: 3.months.ago - 1.week },
      { title: "Plans & rendus 3D",    description: "Moodboard et plan d'aménagement du salon",             position: 3, status: :validee, validate_at: 2.months.ago },
      { title: "Validation client",    description: "Sélection finale des mobiliers et couleurs",           position: 4, status: :validee, validate_at: 2.months.ago - 1.week },
      { title: "Suivi de chantier",    description: "Coordination livraisons et pose",                      position: 5, status: :validee, validate_at: 1.month.ago },
      { title: "Réception des travaux",description: "Visite finale et satisfaction client confirmée",       position: 6, status: :validee, validate_at: 3.weeks.ago }
    ],
    decision_logs: [
      { title: "Validation palette couleurs", description: "Choix final des couleurs à confirmer.",         status: "pending", owner_type: "provider" },
      { title: "Style Japandi retenu",        description: "Style Japandi minimaliste avec bois naturel.",  status: "decided", owner_type: "client",   decided_by: "Nicolas Bernard", decided_at: 3.months.ago },
      { title: "Budget final : 8 500€",       description: "Budget dans les limites prévues.",              status: "decided", owner_type: "provider", decided_by: "Sven Dupont",     decided_at: 3.weeks.ago }
    ]
  }
]

missions_data.each do |mission_data|
  mission = Mission.create!(
    title: mission_data[:title],
    client: mission_data[:client],
    mission_status: mission_data[:status],
    step_template: template,
    portal_token: SecureRandom.hex(10)
  )

  mission_data[:steps].each do |step_attrs|
    Step.create!(
      mission: mission,
      title: step_attrs[:title],
      description: step_attrs[:description],
      position: step_attrs[:position],
      step_status: step_statuses[step_attrs[:status]],
      validate_at: step_attrs[:validate_at]
    )
  end

  mission_data[:decision_logs].each do |log_attrs|
    DecisionLog.create!(
      mission:    mission,
      title:      log_attrs[:title],
      description: log_attrs[:description],
      status:     log_attrs[:status],
      owner_type: log_attrs[:owner_type],
      decided_by: log_attrs[:decided_by],
      decided_at: log_attrs[:decided_at]
    )
  end
end

puts ""
puts "Seeds OK !"
puts "  #{MissionStatus.count} mission statuses"
puts "  #{StepStatus.count} step statuses"
puts "  #{User.count} user  →  #{user.email} / password123"
puts "  #{Profile.count} profile"
puts "  #{Client.count} clients"
puts "  #{Mission.count} missions"
puts "  #{Step.count} steps"
puts "  #{DecisionLog.count} decision logs"
