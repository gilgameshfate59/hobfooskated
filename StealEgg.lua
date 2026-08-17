--[[
	SUPRA | STEAL A EGG

	Farm   — auto steal area eggs, auto place, auto treadmill, guard safety
	Progress — auto base/treadmill upgrades, auto claim offline + index
	ESP    — eggs, rare eggs, guards
	Pets   — auto favorite by rarity/mutation, auto sell by rarity/income/blacklist

	Game bridges everything through the client Network module
	(ReplicatedStorage.Library.Client.Network). Every call also has a raw
	RemoteFunction/RemoteEvent fallback so the script keeps working even if
	the module require is blocked.

	Selling goes through ActiveAssets: RequestSell (RemoteFunction, plain uid
	string); Index: RequestClaimAll is a RemoteFunction answering (ok, reason).

	UI:   WindUI (Footagesus) - MIT
	ESP:  MSESP (mstudio45)   - MIT
	Core: supra-repo/core.lua
--]]

local HUB_NAME = "Steal a Egg"
local HUB_FOLDER = "SupraHub"
local REPO = "https://raw.githubusercontent.com/LogicalGoy/WyndUil/main/"
local DISCORD = "https://discord.gg/WfYDzQfE8y"
local LOGO_ID = 101377976094026


local ACCENT = Color3.fromHex("#4C8DFF")
local DANGER = Color3.fromHex("#E5484D")

-- ============================================================ CORE

local function Fetch(name)
	local ok, body = pcall(game.HttpGet, game, REPO .. name)
	if not ok then
		error(("[%s] failed to download %s: %s"):format(HUB_NAME, name, tostring(body)), 0)
	end
	local chunk, err = loadstring(body)
	if not chunk then
		error(("[%s] failed to compile %s: %s"):format(HUB_NAME, name, tostring(err)), 0)
	end
	return chunk()
end

local WindUI = Fetch("ui.lua")

local Core = Fetch("core.lua").Init({
	HubName = HUB_NAME,
	Folder = HUB_FOLDER,
	Discord = DISCORD,
	LogoId = LOGO_ID,
	Accent = ACCENT,
	Island = { LogoSize = 26 },
})

local Cleanup, Scheduler, Island, Util = Core.Cleanup, Core.Scheduler, Core.Island, Core.Util

local WINDOW_SIZE = Core.IsMobile and Vector2.new(560, 380) or Vector2.new(700, 500)

local SafeCall = Util.SafeCall
local GetCharacter = Util.GetCharacter

local IS_MOBILE = Core.IsMobile
local setclipboard = Core.setclipboard

-- ============================================================ SERVICES

local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function Notify(title, content, duration, icon)
	SafeCall(function()
		WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 3,
			Icon = icon or "info",
		})
	end)
end

-- ============================================================ LOCALIZATION
-- WindUI swaps any text written as "loc:<key>" for the matching entry in
-- the active language. Keys are the English strings themselves, so English
-- needs an identity map and a missing entry is obvious ([key] on screen).
-- Translations are ours, not professionally reviewed.

local LANGUAGES = {
	{ Code = "en", Name = "English" },
	{ Code = "es", Name = "Espanol" },
	{ Code = "pt", Name = "Portugues" },
	{ Code = "fr", Name = "Francais" },
	{ Code = "ru", Name = "Russkiy" },
	{ Code = "tr", Name = "Turkce" },
	{ Code = "zh", Name = "Chinese" },
}

local TRANSLATIONS = {
	en = {
		["Colour scheme for the whole menu"] = "Colour scheme for the whole menu",
		["Language"] = "Language",
		["Menu language"] = "Menu language",
		["Theme"] = "Theme",
		["Add Pet To Blacklist"] = "Add Pet To Blacklist",
		["Auto Claim"] = "Auto Claim",
		["Auto Claim Index Rewards"] = "Auto Claim Index Rewards",
		["Auto Claim Offline Money"] = "Auto Claim Offline Money",
		["Auto Drop Egg"] = "Auto Drop Egg",
		["Auto Equip"] = "Auto Equip",
		["Auto Equip Best"] = "Auto Equip Best",
		["Auto Favorite"] = "Auto Favorite",
		["Auto Hatch Ready Eggs"] = "Auto Hatch Ready Eggs",
		["Auto Place Egg"] = "Auto Place Egg",
		["Auto Sell"] = "Auto Sell",
		["Auto Sell Rarities"] = "Auto Sell Rarities",
		["Auto Steal"] = "Auto Steal",
		["Auto Treadmill"] = "Auto Treadmill",
		["Auto Upgrade Base"] = "Auto Upgrade Base",
		["Auto Upgrade Treadmill"] = "Auto Upgrade Treadmill",
		["Auto Upgrades"] = "Auto Upgrades",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M",
		["Blacklist Selected"] = "Blacklist Selected",
		["Blacklisted Pets"] = "Blacklisted Pets",
		["Buy the next base upgrade whenever affordable."] = "Buy the next base upgrade whenever affordable.",
		["Buy the next treadmill whenever affordable."] = "Buy the next treadmill whenever affordable.",
		["Clear Blacklist"] = "Clear Blacklist",
		["Configs"] = "Configs",
		["Copy Discord Invite"] = "Copy Discord Invite",
		["Costs"] = "Costs",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "Discord Webhook URL",
		["Drop the carried egg the moment a guard chases you."] = "Drop the carried egg the moment a guard chases you.",
		["ESP Eggs"] = "ESP Eggs",
		["ESP Guards"] = "ESP Guards",
		["ESP Rare Eggs"] = "ESP Rare Eggs",
		["Eggs"] = "Eggs",
		["Empty = all areas"] = "Empty = all areas",
		["Empty = all eggs"] = "Empty = all eggs",
		["Equip the best pets into your pen (game's Equip Best)."] = "Equip the best pets into your pen (game's Equip Best).",
		["Favorite Min Rarity"] = "Favorite Min Rarity",
		["Favorite Mutation"] = "Favorite Mutation",
		["Favorite Pets Now"] = "Favorite Pets Now",
		["Game Auto Sell"] = "Game Auto Sell",
		["Guard Chase Distance"] = "Guard Chase Distance",
		["Guard Safety"] = "Guard Safety",
		["Guard Warning"] = "Guard Warning",
		["Guards"] = "Guards",
		["Hatch growing eggs as soon as they're ready."] = "Hatch growing eggs as soon as they're ready.",
		["Hop Speed"] = "Hop Speed",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Hops per second. Higher is faster but easier for the game to correct.",
		["Interface"] = "Interface",
		["Load"] = "Load",
		["Mark every area egg with name, rarity and distance."] = "Mark every area egg with name, rarity and distance.",
		["Mark guards with state and distance."] = "Mark guards with state and distance.",
		["Menu Key"] = "Menu Key",
		["Minimum Rarity"] = "Minimum Rarity",
		["Movement"] = "Movement",
		["Name"] = "Name",
		["Note"] = "Note",
		["Notify when a guard is chasing you."] = "Notify when a guard is chasing you.",
		["Only mark eggs at or above the threshold below."] = "Only mark eggs at or above the threshold below.",
		["Only send for eggs at or above this rarity"] = "Only send for eggs at or above this rarity",
		["Paste your Discord webhook URL here"] = "Paste your Discord webhook URL here",
		["Pet Income Threshold"] = "Pet Income Threshold",
		["Pet Max Rarity"] = "Pet Max Rarity",
		["Place Egg"] = "Place Egg",
		["Place Rule"] = "Place Rule",
		["Place carried eggs into your pen when you get home."] = "Place carried eggs into your pen when you get home.",
		["Rare Threshold"] = "Rare Threshold",
		["Remove Selected"] = "Remove Selected",
		["Restores everything this script changed and closes the menu"] = "Restores everything this script changed and closes the menu",
		["Save"] = "Save",
		["Saved"] = "Saved",
		["Select a pet, it will never be sold"] = "Select a pet, it will never be sold",
		["Sell Blacklist"] = "Sell Blacklist",
		["Sell Pets Now"] = "Sell Pets Now",
		["Sell Rule"] = "Sell Rule",
		["Sell pets at or below this rarity."] = "Sell pets at or below this rarity.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Sell pets below this income. 0 or empty = disabled. e.g. 10M",
		["Send a Discord notification when an egg is stolen"] = "Send a Discord notification when an egg is stolen",
		["Send a test notification to verify the URL"] = "Send a test notification to verify the URL",
		["Show Island"] = "Show Island",
		["Steal"] = "Steal",
		["Steal Hop Size"] = "Steal Hop Size",
		["Steal Priority"] = "Steal Priority",
		["Steal eggs from areas, run them home and place them."] = "Steal eggs from areas, run them home and place them.",
		["Target Areas"] = "Target Areas",
		["Target Eggs"] = "Target Eggs",
		["Test Webhook"] = "Test Webhook",
		["The game's own auto sell. Runs server side, works offline."] = "The game's own auto sell. Runs server side, works offline.",
		["The status pill at the top of the screen"] = "The status pill at the top of the screen",
		["Train when idle. Pauses while carrying or stealing."] = "Train when idle. Pauses while carrying or stealing.",
		["Treadmill"] = "Treadmill",
		["UI Scale"] = "UI Scale",
		["Unavailable"] = "Unavailable",
		["Unload"] = "Unload",
		["Webhook Egg Steal"] = "Webhook Egg Steal",
		["Webhook Min Rarity"] = "Webhook Min Rarity",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Your executor exposes no HTTP request function, so webhooks are disabled.",
		["Your executor has no file access, so configs are disabled."] = "Your executor has no file access, so configs are disabled.",
	},
	es = {
		["Colour scheme for the whole menu"] = "Esquema de color de todo el menu",
		["Language"] = "Idioma",
		["Menu language"] = "Idioma del menu",
		["Theme"] = "Tema",
		["Add Pet To Blacklist"] = "Anadir mascota a la lista negra",
		["Auto Claim"] = "Reclamo automatico",
		["Auto Claim Index Rewards"] = "Reclamar recompensas del indice",
		["Auto Claim Offline Money"] = "Reclamar dinero offline",
		["Auto Drop Egg"] = "Soltar huevo automatico",
		["Auto Equip"] = "Equipar automatico",
		["Auto Equip Best"] = "Equipar los mejores",
		["Auto Favorite"] = "Favorito automatico",
		["Auto Hatch Ready Eggs"] = "Eclosionar huevos listos",
		["Auto Place Egg"] = "Colocar huevo automatico",
		["Auto Sell"] = "Venta automatica",
		["Auto Sell Rarities"] = "Rarezas a vender",
		["Auto Steal"] = "Robo automatico",
		["Auto Treadmill"] = "Cinta automatica",
		["Auto Upgrade Base"] = "Mejorar base automatico",
		["Auto Upgrade Treadmill"] = "Mejorar cinta automatico",
		["Auto Upgrades"] = "Mejoras automaticas",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "Base Nv2: 1K | Nv3: 1M | Nv4: 75M | Cinta Nv2: 15K | Nv3: 250K | Nv4: 5M",
		["Blacklist Selected"] = "Anadir a la lista negra",
		["Blacklisted Pets"] = "Mascotas en lista negra",
		["Buy the next base upgrade whenever affordable."] = "Compra la siguiente mejora de base cuando puedas pagarla.",
		["Buy the next treadmill whenever affordable."] = "Compra la siguiente cinta cuando puedas pagarla.",
		["Clear Blacklist"] = "Vaciar lista negra",
		["Configs"] = "Configuraciones",
		["Copy Discord Invite"] = "Copiar invitacion de Discord",
		["Costs"] = "Costes",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "URL del webhook de Discord",
		["Drop the carried egg the moment a guard chases you."] = "Suelta el huevo en cuanto un guardia te persiga.",
		["ESP Eggs"] = "ESP de huevos",
		["ESP Guards"] = "ESP de guardias",
		["ESP Rare Eggs"] = "ESP de huevos raros",
		["Eggs"] = "Huevos",
		["Empty = all areas"] = "Vacio = todas las areas",
		["Empty = all eggs"] = "Vacio = todos los huevos",
		["Equip the best pets into your pen (game's Equip Best)."] = "Equipa las mejores mascotas en tu corral (Equip Best del juego).",
		["Favorite Min Rarity"] = "Rareza minima para favorito",
		["Favorite Mutation"] = "Mutacion favorita",
		["Favorite Pets Now"] = "Marcar favoritos ahora",
		["Game Auto Sell"] = "Venta automatica del juego",
		["Guard Chase Distance"] = "Distancia de persecucion",
		["Guard Safety"] = "Seguridad ante guardias",
		["Guard Warning"] = "Aviso de guardia",
		["Guards"] = "Guardias",
		["Hatch growing eggs as soon as they're ready."] = "Eclosiona los huevos en cuanto esten listos.",
		["Hop Speed"] = "Velocidad de salto",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Saltos por segundo. Mas alto es mas rapido pero el juego lo corrige antes.",
		["Interface"] = "Interfaz",
		["Load"] = "Cargar",
		["Mark every area egg with name, rarity and distance."] = "Marca cada huevo con nombre, rareza y distancia.",
		["Mark guards with state and distance."] = "Marca los guardias con estado y distancia.",
		["Menu Key"] = "Tecla del menu",
		["Minimum Rarity"] = "Rareza minima",
		["Movement"] = "Movimiento",
		["Name"] = "Nombre",
		["Note"] = "Nota",
		["Notify when a guard is chasing you."] = "Avisa cuando un guardia te persigue.",
		["Only mark eggs at or above the threshold below."] = "Solo marca huevos con rareza igual o superior al umbral.",
		["Only send for eggs at or above this rarity"] = "Solo envia huevos de esta rareza o superior",
		["Paste your Discord webhook URL here"] = "Pega aqui la URL de tu webhook de Discord",
		["Pet Income Threshold"] = "Umbral de ingresos",
		["Pet Max Rarity"] = "Rareza maxima",
		["Place Egg"] = "Colocar huevo",
		["Place Rule"] = "Regla de colocacion",
		["Place carried eggs into your pen when you get home."] = "Coloca los huevos en tu corral al llegar a casa.",
		["Rare Threshold"] = "Umbral de rareza",
		["Remove Selected"] = "Quitar seleccionado",
		["Restores everything this script changed and closes the menu"] = "Revierte todo lo que cambio el script y cierra el menu",
		["Save"] = "Guardar",
		["Saved"] = "Guardados",
		["Select a pet, it will never be sold"] = "Elige una mascota, nunca se vendera",
		["Sell Blacklist"] = "Lista negra de venta",
		["Sell Pets Now"] = "Vender mascotas ahora",
		["Sell Rule"] = "Regla de venta",
		["Sell pets at or below this rarity."] = "Vende mascotas de esta rareza o inferior.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Vende mascotas por debajo de estos ingresos. 0 o vacio = desactivado. ej. 10M",
		["Send a Discord notification when an egg is stolen"] = "Envia una notificacion a Discord al robar un huevo",
		["Send a test notification to verify the URL"] = "Envia una notificacion de prueba para verificar la URL",
		["Show Island"] = "Mostrar isla",
		["Steal"] = "Robar",
		["Steal Hop Size"] = "Tamano del salto",
		["Steal Priority"] = "Prioridad de robo",
		["Steal eggs from areas, run them home and place them."] = "Roba huevos de las areas, llevalos a casa y colocalos.",
		["Target Areas"] = "Areas objetivo",
		["Target Eggs"] = "Huevos objetivo",
		["Test Webhook"] = "Probar webhook",
		["The game's own auto sell. Runs server side, works offline."] = "La venta automatica del propio juego. Corre en el servidor y funciona offline.",
		["The status pill at the top of the screen"] = "La capsula de estado en la parte superior",
		["Train when idle. Pauses while carrying or stealing."] = "Entrena cuando estas libre. Se pausa al cargar o robar.",
		["Treadmill"] = "Cinta de correr",
		["UI Scale"] = "Escala de la interfaz",
		["Unavailable"] = "No disponible",
		["Unload"] = "Descargar",
		["Webhook Egg Steal"] = "Webhook al robar huevo",
		["Webhook Min Rarity"] = "Rareza minima del webhook",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Tu executor no expone una funcion HTTP, los webhooks estan desactivados.",
		["Your executor has no file access, so configs are disabled."] = "Tu executor no tiene acceso a archivos, las configuraciones estan desactivadas.",
	},
	pt = {
		["Colour scheme for the whole menu"] = "Esquema de cores de todo o menu",
		["Language"] = "Idioma",
		["Menu language"] = "Idioma do menu",
		["Theme"] = "Tema",
		["Add Pet To Blacklist"] = "Adicionar pet a lista negra",
		["Auto Claim"] = "Coleta automatica",
		["Auto Claim Index Rewards"] = "Coletar recompensas do indice",
		["Auto Claim Offline Money"] = "Coletar dinheiro offline",
		["Auto Drop Egg"] = "Soltar ovo automatico",
		["Auto Equip"] = "Equipar automatico",
		["Auto Equip Best"] = "Equipar os melhores",
		["Auto Favorite"] = "Favoritar automatico",
		["Auto Hatch Ready Eggs"] = "Chocar ovos prontos",
		["Auto Place Egg"] = "Colocar ovo automatico",
		["Auto Sell"] = "Venda automatica",
		["Auto Sell Rarities"] = "Raridades para vender",
		["Auto Steal"] = "Roubo automatico",
		["Auto Treadmill"] = "Esteira automatica",
		["Auto Upgrade Base"] = "Melhorar base automatico",
		["Auto Upgrade Treadmill"] = "Melhorar esteira automatico",
		["Auto Upgrades"] = "Melhorias automaticas",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "Base Nv2: 1K | Nv3: 1M | Nv4: 75M | Esteira Nv2: 15K | Nv3: 250K | Nv4: 5M",
		["Blacklist Selected"] = "Adicionar a lista negra",
		["Blacklisted Pets"] = "Pets na lista negra",
		["Buy the next base upgrade whenever affordable."] = "Compra a proxima melhoria de base quando der.",
		["Buy the next treadmill whenever affordable."] = "Compra a proxima esteira quando der.",
		["Clear Blacklist"] = "Limpar lista negra",
		["Configs"] = "Configuracoes",
		["Copy Discord Invite"] = "Copiar convite do Discord",
		["Costs"] = "Custos",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "URL do webhook do Discord",
		["Drop the carried egg the moment a guard chases you."] = "Solta o ovo assim que um guarda te perseguir.",
		["ESP Eggs"] = "ESP de ovos",
		["ESP Guards"] = "ESP de guardas",
		["ESP Rare Eggs"] = "ESP de ovos raros",
		["Eggs"] = "Ovos",
		["Empty = all areas"] = "Vazio = todas as areas",
		["Empty = all eggs"] = "Vazio = todos os ovos",
		["Equip the best pets into your pen (game's Equip Best)."] = "Equipa os melhores pets no seu curral (Equip Best do jogo).",
		["Favorite Min Rarity"] = "Raridade minima para favoritar",
		["Favorite Mutation"] = "Mutacao favorita",
		["Favorite Pets Now"] = "Favoritar agora",
		["Game Auto Sell"] = "Venda automatica do jogo",
		["Guard Chase Distance"] = "Distancia de perseguicao",
		["Guard Safety"] = "Seguranca contra guardas",
		["Guard Warning"] = "Aviso de guarda",
		["Guards"] = "Guardas",
		["Hatch growing eggs as soon as they're ready."] = "Choca os ovos assim que estiverem prontos.",
		["Hop Speed"] = "Velocidade de salto",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Saltos por segundo. Maior e mais rapido mas o jogo corrige mais facil.",
		["Interface"] = "Interface",
		["Load"] = "Carregar",
		["Mark every area egg with name, rarity and distance."] = "Marca cada ovo com nome, raridade e distancia.",
		["Mark guards with state and distance."] = "Marca os guardas com estado e distancia.",
		["Menu Key"] = "Tecla do menu",
		["Minimum Rarity"] = "Raridade minima",
		["Movement"] = "Movimento",
		["Name"] = "Nome",
		["Note"] = "Nota",
		["Notify when a guard is chasing you."] = "Avisa quando um guarda te persegue.",
		["Only mark eggs at or above the threshold below."] = "So marca ovos com raridade igual ou acima do limite.",
		["Only send for eggs at or above this rarity"] = "So envia ovos desta raridade ou acima",
		["Paste your Discord webhook URL here"] = "Cole aqui a URL do seu webhook do Discord",
		["Pet Income Threshold"] = "Limite de renda",
		["Pet Max Rarity"] = "Raridade maxima",
		["Place Egg"] = "Colocar ovo",
		["Place Rule"] = "Regra de colocacao",
		["Place carried eggs into your pen when you get home."] = "Coloca os ovos no seu curral ao chegar em casa.",
		["Rare Threshold"] = "Limite de raridade",
		["Remove Selected"] = "Remover selecionado",
		["Restores everything this script changed and closes the menu"] = "Reverte tudo que o script mudou e fecha o menu",
		["Save"] = "Salvar",
		["Saved"] = "Salvos",
		["Select a pet, it will never be sold"] = "Escolha um pet, ele nunca sera vendido",
		["Sell Blacklist"] = "Lista negra de venda",
		["Sell Pets Now"] = "Vender pets agora",
		["Sell Rule"] = "Regra de venda",
		["Sell pets at or below this rarity."] = "Vende pets desta raridade ou abaixo.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Vende pets abaixo desta renda. 0 ou vazio = desativado. ex. 10M",
		["Send a Discord notification when an egg is stolen"] = "Envia uma notificacao ao Discord ao roubar um ovo",
		["Send a test notification to verify the URL"] = "Envia uma notificacao de teste para verificar a URL",
		["Show Island"] = "Mostrar ilha",
		["Steal"] = "Roubar",
		["Steal Hop Size"] = "Tamanho do salto",
		["Steal Priority"] = "Prioridade de roubo",
		["Steal eggs from areas, run them home and place them."] = "Rouba ovos das areas, leva pra casa e coloca.",
		["Target Areas"] = "Areas alvo",
		["Target Eggs"] = "Ovos alvo",
		["Test Webhook"] = "Testar webhook",
		["The game's own auto sell. Runs server side, works offline."] = "A venda automatica do proprio jogo. Roda no servidor e funciona offline.",
		["The status pill at the top of the screen"] = "A capsula de status no topo da tela",
		["Train when idle. Pauses while carrying or stealing."] = "Treina quando esta livre. Pausa ao carregar ou roubar.",
		["Treadmill"] = "Esteira",
		["UI Scale"] = "Escala da interface",
		["Unavailable"] = "Indisponivel",
		["Unload"] = "Descarregar",
		["Webhook Egg Steal"] = "Webhook ao roubar ovo",
		["Webhook Min Rarity"] = "Raridade minima do webhook",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Seu executor nao expoe funcao HTTP, os webhooks estao desativados.",
		["Your executor has no file access, so configs are disabled."] = "Seu executor nao tem acesso a arquivos, as configuracoes estao desativadas.",
	},
	fr = {
		["Colour scheme for the whole menu"] = "Palette de couleurs de tout le menu",
		["Language"] = "Langue",
		["Menu language"] = "Langue du menu",
		["Theme"] = "Theme",
		["Add Pet To Blacklist"] = "Ajouter un familier a la liste noire",
		["Auto Claim"] = "Reclamation auto",
		["Auto Claim Index Rewards"] = "Recuperer les recompenses de l'index",
		["Auto Claim Offline Money"] = "Recuperer l'argent hors ligne",
		["Auto Drop Egg"] = "Lacher l'oeuf auto",
		["Auto Equip"] = "Equipement auto",
		["Auto Equip Best"] = "Equiper les meilleurs",
		["Auto Favorite"] = "Favori auto",
		["Auto Hatch Ready Eggs"] = "Faire eclore les oeufs prets",
		["Auto Place Egg"] = "Placer l'oeuf auto",
		["Auto Sell"] = "Vente auto",
		["Auto Sell Rarities"] = "Raretes a vendre",
		["Auto Steal"] = "Vol auto",
		["Auto Treadmill"] = "Tapis roulant auto",
		["Auto Upgrade Base"] = "Ameliorer la base auto",
		["Auto Upgrade Treadmill"] = "Ameliorer le tapis auto",
		["Auto Upgrades"] = "Ameliorations auto",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "Base Niv2: 1K | Niv3: 1M | Niv4: 75M | Tapis Niv2: 15K | Niv3: 250K | Niv4: 5M",
		["Blacklist Selected"] = "Mettre en liste noire",
		["Blacklisted Pets"] = "Familiers en liste noire",
		["Buy the next base upgrade whenever affordable."] = "Achete la prochaine amelioration de base des que possible.",
		["Buy the next treadmill whenever affordable."] = "Achete le prochain tapis des que possible.",
		["Clear Blacklist"] = "Vider la liste noire",
		["Configs"] = "Configurations",
		["Copy Discord Invite"] = "Copier l'invitation Discord",
		["Costs"] = "Couts",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "URL du webhook Discord",
		["Drop the carried egg the moment a guard chases you."] = "Lache l'oeuf des qu'un garde te poursuit.",
		["ESP Eggs"] = "ESP des oeufs",
		["ESP Guards"] = "ESP des gardes",
		["ESP Rare Eggs"] = "ESP des oeufs rares",
		["Eggs"] = "Oeufs",
		["Empty = all areas"] = "Vide = toutes les zones",
		["Empty = all eggs"] = "Vide = tous les oeufs",
		["Equip the best pets into your pen (game's Equip Best)."] = "Equipe les meilleurs familiers dans ton enclos (Equip Best du jeu).",
		["Favorite Min Rarity"] = "Rarete min. pour favori",
		["Favorite Mutation"] = "Mutation favorite",
		["Favorite Pets Now"] = "Mettre en favori maintenant",
		["Game Auto Sell"] = "Vente auto du jeu",
		["Guard Chase Distance"] = "Distance de poursuite",
		["Guard Safety"] = "Securite face aux gardes",
		["Guard Warning"] = "Alerte garde",
		["Guards"] = "Gardes",
		["Hatch growing eggs as soon as they're ready."] = "Fait eclore les oeufs des qu'ils sont prets.",
		["Hop Speed"] = "Vitesse de saut",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Sauts par seconde. Plus eleve est plus rapide mais plus facile a corriger pour le jeu.",
		["Interface"] = "Interface",
		["Load"] = "Charger",
		["Mark every area egg with name, rarity and distance."] = "Marque chaque oeuf avec nom, rarete et distance.",
		["Mark guards with state and distance."] = "Marque les gardes avec etat et distance.",
		["Menu Key"] = "Touche du menu",
		["Minimum Rarity"] = "Rarete minimale",
		["Movement"] = "Deplacement",
		["Name"] = "Nom",
		["Note"] = "Note",
		["Notify when a guard is chasing you."] = "Previent quand un garde te poursuit.",
		["Only mark eggs at or above the threshold below."] = "Ne marque que les oeufs au-dessus du seuil.",
		["Only send for eggs at or above this rarity"] = "N'envoie que les oeufs de cette rarete ou plus",
		["Paste your Discord webhook URL here"] = "Colle ici l'URL de ton webhook Discord",
		["Pet Income Threshold"] = "Seuil de revenu",
		["Pet Max Rarity"] = "Rarete maximale",
		["Place Egg"] = "Placer l'oeuf",
		["Place Rule"] = "Regle de placement",
		["Place carried eggs into your pen when you get home."] = "Place les oeufs dans ton enclos en rentrant.",
		["Rare Threshold"] = "Seuil de rarete",
		["Remove Selected"] = "Retirer la selection",
		["Restores everything this script changed and closes the menu"] = "Restaure tout ce que le script a modifie et ferme le menu",
		["Save"] = "Sauvegarder",
		["Saved"] = "Sauvegardes",
		["Select a pet, it will never be sold"] = "Choisis un familier, il ne sera jamais vendu",
		["Sell Blacklist"] = "Liste noire de vente",
		["Sell Pets Now"] = "Vendre les familiers maintenant",
		["Sell Rule"] = "Regle de vente",
		["Sell pets at or below this rarity."] = "Vend les familiers de cette rarete ou moins.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Vend les familiers sous ce revenu. 0 ou vide = desactive. ex. 10M",
		["Send a Discord notification when an egg is stolen"] = "Envoie une notification Discord quand un oeuf est vole",
		["Send a test notification to verify the URL"] = "Envoie une notification de test pour verifier l'URL",
		["Show Island"] = "Afficher l'ilot",
		["Steal"] = "Voler",
		["Steal Hop Size"] = "Taille du saut",
		["Steal Priority"] = "Priorite de vol",
		["Steal eggs from areas, run them home and place them."] = "Vole les oeufs des zones, ramene-les et place-les.",
		["Target Areas"] = "Zones ciblees",
		["Target Eggs"] = "Oeufs cibles",
		["Test Webhook"] = "Tester le webhook",
		["The game's own auto sell. Runs server side, works offline."] = "La vente auto du jeu. Cote serveur, fonctionne hors ligne.",
		["The status pill at the top of the screen"] = "La pastille d'etat en haut de l'ecran",
		["Train when idle. Pauses while carrying or stealing."] = "S'entraine quand inactif. Pause pendant le transport ou le vol.",
		["Treadmill"] = "Tapis roulant",
		["UI Scale"] = "Echelle de l'interface",
		["Unavailable"] = "Indisponible",
		["Unload"] = "Decharger",
		["Webhook Egg Steal"] = "Webhook au vol d'oeuf",
		["Webhook Min Rarity"] = "Rarete min. du webhook",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Ton executor n'expose aucune fonction HTTP, les webhooks sont desactives.",
		["Your executor has no file access, so configs are disabled."] = "Ton executor n'a pas d'acces fichier, les configurations sont desactivees.",
	},
	ru = {
		["Colour scheme for the whole menu"] = "Цветовая схема всего меню",
		["Language"] = "Язык",
		["Menu language"] = "Язык меню",
		["Theme"] = "Тема",
		["Add Pet To Blacklist"] = "Добавить питомца в чёрный список",
		["Auto Claim"] = "Автосбор",
		["Auto Claim Index Rewards"] = "Автосбор наград индекса",
		["Auto Claim Offline Money"] = "Автосбор офлайн-денег",
		["Auto Drop Egg"] = "Автосброс яйца",
		["Auto Equip"] = "Автоэкипировка",
		["Auto Equip Best"] = "Экипировать лучших",
		["Auto Favorite"] = "Автоизбранное",
		["Auto Hatch Ready Eggs"] = "Автовылупление готовых яиц",
		["Auto Place Egg"] = "Авторазмещение яйца",
		["Auto Sell"] = "Автопродажа",
		["Auto Sell Rarities"] = "Редкости для продажи",
		["Auto Steal"] = "Автокража",
		["Auto Treadmill"] = "Автобеговая дорожка",
		["Auto Upgrade Base"] = "Автоулучшение базы",
		["Auto Upgrade Treadmill"] = "Автоулучшение дорожки",
		["Auto Upgrades"] = "Автоулучшения",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "База ур.2: 1K | ур.3: 1M | ур.4: 75M | Дорожка ур.2: 15K | ур.3: 250K | ур.4: 5M",
		["Blacklist Selected"] = "В чёрный список",
		["Blacklisted Pets"] = "Питомцы в чёрном списке",
		["Buy the next base upgrade whenever affordable."] = "Покупает следующее улучшение базы, когда хватает денег.",
		["Buy the next treadmill whenever affordable."] = "Покупает следующую дорожку, когда хватает денег.",
		["Clear Blacklist"] = "Очистить чёрный список",
		["Configs"] = "Конфиги",
		["Copy Discord Invite"] = "Скопировать приглашение Discord",
		["Costs"] = "Стоимость",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "URL вебхука Discord",
		["Drop the carried egg the moment a guard chases you."] = "Бросает яйцо, как только охранник начинает погоню.",
		["ESP Eggs"] = "ESP яиц",
		["ESP Guards"] = "ESP охранников",
		["ESP Rare Eggs"] = "ESP редких яиц",
		["Eggs"] = "Яйца",
		["Empty = all areas"] = "Пусто = все зоны",
		["Empty = all eggs"] = "Пусто = все яйца",
		["Equip the best pets into your pen (game's Equip Best)."] = "Ставит лучших питомцев в загон (функция игры Equip Best).",
		["Favorite Min Rarity"] = "Мин. редкость для избранного",
		["Favorite Mutation"] = "Избранная мутация",
		["Favorite Pets Now"] = "Добавить в избранное сейчас",
		["Game Auto Sell"] = "Автопродажа игры",
		["Guard Chase Distance"] = "Дистанция погони",
		["Guard Safety"] = "Защита от охранников",
		["Guard Warning"] = "Предупреждение об охраннике",
		["Guards"] = "Охранники",
		["Hatch growing eggs as soon as they're ready."] = "Вылупляет яйца, как только они готовы.",
		["Hop Speed"] = "Скорость прыжков",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Прыжков в секунду. Больше — быстрее, но игре легче это откатить.",
		["Interface"] = "Интерфейс",
		["Load"] = "Загрузить",
		["Mark every area egg with name, rarity and distance."] = "Отмечает каждое яйцо: имя, редкость, расстояние.",
		["Mark guards with state and distance."] = "Отмечает охранников: состояние и расстояние.",
		["Menu Key"] = "Клавиша меню",
		["Minimum Rarity"] = "Мин. редкость",
		["Movement"] = "Передвижение",
		["Name"] = "Название",
		["Note"] = "Примечание",
		["Notify when a guard is chasing you."] = "Уведомляет, когда охранник гонится за вами.",
		["Only mark eggs at or above the threshold below."] = "Отмечает только яйца не ниже порога.",
		["Only send for eggs at or above this rarity"] = "Отправлять только яйца не ниже этой редкости",
		["Paste your Discord webhook URL here"] = "Вставьте сюда URL вебхука Discord",
		["Pet Income Threshold"] = "Порог дохода",
		["Pet Max Rarity"] = "Макс. редкость",
		["Place Egg"] = "Размещение яйца",
		["Place Rule"] = "Правило размещения",
		["Place carried eggs into your pen when you get home."] = "Кладёт принесённые яйца в загон по возвращении.",
		["Rare Threshold"] = "Порог редкости",
		["Remove Selected"] = "Убрать выбранное",
		["Restores everything this script changed and closes the menu"] = "Возвращает всё изменённое скриптом и закрывает меню",
		["Save"] = "Сохранить",
		["Saved"] = "Сохранённые",
		["Select a pet, it will never be sold"] = "Выберите питомца — он никогда не будет продан",
		["Sell Blacklist"] = "Чёрный список продажи",
		["Sell Pets Now"] = "Продать питомцев сейчас",
		["Sell Rule"] = "Правило продажи",
		["Sell pets at or below this rarity."] = "Продаёт питомцев не выше этой редкости.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Продаёт питомцев с доходом ниже этого. 0 или пусто = выкл. напр. 10M",
		["Send a Discord notification when an egg is stolen"] = "Отправляет уведомление в Discord при краже яйца",
		["Send a test notification to verify the URL"] = "Отправляет тестовое уведомление для проверки URL",
		["Show Island"] = "Показать островок",
		["Steal"] = "Кража",
		["Steal Hop Size"] = "Длина прыжка",
		["Steal Priority"] = "Приоритет кражи",
		["Steal eggs from areas, run them home and place them."] = "Крадёт яйца из зон, несёт домой и размещает.",
		["Target Areas"] = "Целевые зоны",
		["Target Eggs"] = "Целевые яйца",
		["Test Webhook"] = "Проверить вебхук",
		["The game's own auto sell. Runs server side, works offline."] = "Собственная автопродажа игры. Работает на сервере и офлайн.",
		["The status pill at the top of the screen"] = "Капсула состояния вверху экрана",
		["Train when idle. Pauses while carrying or stealing."] = "Тренируется в простое. Пауза при переносе или краже.",
		["Treadmill"] = "Беговая дорожка",
		["UI Scale"] = "Масштаб интерфейса",
		["Unavailable"] = "Недоступно",
		["Unload"] = "Выгрузка",
		["Webhook Egg Steal"] = "Вебхук при краже яйца",
		["Webhook Min Rarity"] = "Мин. редкость для вебхука",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Ваш экзекьютор не даёт HTTP-функции, вебхуки отключены.",
		["Your executor has no file access, so configs are disabled."] = "Ваш экзекьютор не имеет доступа к файлам, конфиги отключены.",
	},
	tr = {
		["Colour scheme for the whole menu"] = "Tum menunun renk semasi",
		["Language"] = "Dil",
		["Menu language"] = "Menu dili",
		["Theme"] = "Tema",
		["Add Pet To Blacklist"] = "Evcil hayvani kara listeye ekle",
		["Auto Claim"] = "Otomatik Alma",
		["Auto Claim Index Rewards"] = "Index odullerini otomatik al",
		["Auto Claim Offline Money"] = "Cevrimdisi parayi otomatik al",
		["Auto Drop Egg"] = "Yumurtayi otomatik birak",
		["Auto Equip"] = "Otomatik Kusan",
		["Auto Equip Best"] = "En iyileri kusan",
		["Auto Favorite"] = "Otomatik Favori",
		["Auto Hatch Ready Eggs"] = "Hazir yumurtalari cikart",
		["Auto Place Egg"] = "Yumurtayi otomatik yerlestir",
		["Auto Sell"] = "Otomatik Satis",
		["Auto Sell Rarities"] = "Satilacak nadirlikler",
		["Auto Steal"] = "Otomatik Calma",
		["Auto Treadmill"] = "Otomatik Kosu Bandi",
		["Auto Upgrade Base"] = "Ussu otomatik yukselt",
		["Auto Upgrade Treadmill"] = "Kosu bandini otomatik yukselt",
		["Auto Upgrades"] = "Otomatik Yukseltmeler",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "Us Sv2: 1K | Sv3: 1M | Sv4: 75M | Kosu Bandi Sv2: 15K | Sv3: 250K | Sv4: 5M",
		["Blacklist Selected"] = "Kara listeye ekle",
		["Blacklisted Pets"] = "Kara listedeki hayvanlar",
		["Buy the next base upgrade whenever affordable."] = "Karsilayabildiginde bir sonraki us yukseltmesini satin alir.",
		["Buy the next treadmill whenever affordable."] = "Karsilayabildiginde bir sonraki kosu bandini satin alir.",
		["Clear Blacklist"] = "Kara listeyi temizle",
		["Configs"] = "Yapilandirmalar",
		["Copy Discord Invite"] = "Discord davetini kopyala",
		["Costs"] = "Maliyetler",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "Discord webhook URL'si",
		["Drop the carried egg the moment a guard chases you."] = "Bir muhafiz kovaladigi anda yumurtayi birakir.",
		["ESP Eggs"] = "Yumurta ESP",
		["ESP Guards"] = "Muhafiz ESP",
		["ESP Rare Eggs"] = "Nadir yumurta ESP",
		["Eggs"] = "Yumurtalar",
		["Empty = all areas"] = "Bos = tum bolgeler",
		["Empty = all eggs"] = "Bos = tum yumurtalar",
		["Equip the best pets into your pen (game's Equip Best)."] = "En iyi hayvanlari agilina kusanir (oyunun Equip Best ozelligi).",
		["Favorite Min Rarity"] = "Favori icin min nadirlik",
		["Favorite Mutation"] = "Favori mutasyon",
		["Favorite Pets Now"] = "Simdi favorile",
		["Game Auto Sell"] = "Oyunun otomatik satisi",
		["Guard Chase Distance"] = "Kovalama mesafesi",
		["Guard Safety"] = "Muhafiz guvenligi",
		["Guard Warning"] = "Muhafiz uyarisi",
		["Guards"] = "Muhafizlar",
		["Hatch growing eggs as soon as they're ready."] = "Yumurtalar hazir olur olmaz cikartir.",
		["Hop Speed"] = "Ziplama hizi",
		["Hops per second. Higher is faster but easier for the game to correct."] = "Saniyedeki ziplama. Yuksek olan daha hizli ama oyunun duzeltmesi daha kolay.",
		["Interface"] = "Arayuz",
		["Load"] = "Yukle",
		["Mark every area egg with name, rarity and distance."] = "Her yumurtayi ad, nadirlik ve mesafe ile isaretler.",
		["Mark guards with state and distance."] = "Muhafizlari durum ve mesafe ile isaretler.",
		["Menu Key"] = "Menu tusu",
		["Minimum Rarity"] = "Minimum nadirlik",
		["Movement"] = "Hareket",
		["Name"] = "Ad",
		["Note"] = "Not",
		["Notify when a guard is chasing you."] = "Bir muhafiz kovaladiginda bildirir.",
		["Only mark eggs at or above the threshold below."] = "Sadece esigin ustundeki yumurtalari isaretler.",
		["Only send for eggs at or above this rarity"] = "Sadece bu nadirlik ve ustu icin gonder",
		["Paste your Discord webhook URL here"] = "Discord webhook URL'ni buraya yapistir",
		["Pet Income Threshold"] = "Gelir esigi",
		["Pet Max Rarity"] = "Maksimum nadirlik",
		["Place Egg"] = "Yumurta yerlestir",
		["Place Rule"] = "Yerlestirme kurali",
		["Place carried eggs into your pen when you get home."] = "Eve varinca yumurtalari agilina koyar.",
		["Rare Threshold"] = "Nadirlik esigi",
		["Remove Selected"] = "Secileni kaldir",
		["Restores everything this script changed and closes the menu"] = "Betigin degistirdigi her seyi geri alir ve menuyu kapatir",
		["Save"] = "Kaydet",
		["Saved"] = "Kayitli",
		["Select a pet, it will never be sold"] = "Bir hayvan sec, asla satilmaz",
		["Sell Blacklist"] = "Satis kara listesi",
		["Sell Pets Now"] = "Simdi sat",
		["Sell Rule"] = "Satis kurali",
		["Sell pets at or below this rarity."] = "Bu nadirlik ve altindaki hayvanlari satar.",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "Bu gelirin altindaki hayvanlari satar. 0 veya bos = kapali. orn. 10M",
		["Send a Discord notification when an egg is stolen"] = "Bir yumurta calindiginda Discord bildirimi gonderir",
		["Send a test notification to verify the URL"] = "URL'yi dogrulamak icin test bildirimi gonderir",
		["Show Island"] = "Adayi goster",
		["Steal"] = "Calma",
		["Steal Hop Size"] = "Ziplama boyutu",
		["Steal Priority"] = "Calma onceligi",
		["Steal eggs from areas, run them home and place them."] = "Bolgelerden yumurta calar, eve goturur ve yerlestirir.",
		["Target Areas"] = "Hedef bolgeler",
		["Target Eggs"] = "Hedef yumurtalar",
		["Test Webhook"] = "Webhook'u test et",
		["The game's own auto sell. Runs server side, works offline."] = "Oyunun kendi otomatik satisi. Sunucuda calisir, cevrimdisi de calisir.",
		["The status pill at the top of the screen"] = "Ekranin ustundeki durum kapsulu",
		["Train when idle. Pauses while carrying or stealing."] = "Bostayken antrenman yapar. Tasirken veya calarken duraklar.",
		["Treadmill"] = "Kosu bandi",
		["UI Scale"] = "Arayuz olcegi",
		["Unavailable"] = "Kullanilamaz",
		["Unload"] = "Kaldir",
		["Webhook Egg Steal"] = "Yumurta calma webhook'u",
		["Webhook Min Rarity"] = "Webhook min nadirlik",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "Executor'un HTTP istek fonksiyonu sunmuyor, webhook'lar kapali.",
		["Your executor has no file access, so configs are disabled."] = "Executor'un dosya erisimi yok, yapilandirmalar kapali.",
	},
	zh = {
		["Colour scheme for the whole menu"] = "整个菜单的配色方案",
		["Language"] = "语言",
		["Menu language"] = "菜单语言",
		["Theme"] = "主题",
		["Add Pet To Blacklist"] = "将宠物加入黑名单",
		["Auto Claim"] = "自动领取",
		["Auto Claim Index Rewards"] = "自动领取图鉴奖励",
		["Auto Claim Offline Money"] = "自动领取离线金币",
		["Auto Drop Egg"] = "自动丢弃蛋",
		["Auto Equip"] = "自动装备",
		["Auto Equip Best"] = "装备最佳宠物",
		["Auto Favorite"] = "自动收藏",
		["Auto Hatch Ready Eggs"] = "自动孵化就绪的蛋",
		["Auto Place Egg"] = "自动放置蛋",
		["Auto Sell"] = "自动出售",
		["Auto Sell Rarities"] = "自动出售稀有度",
		["Auto Steal"] = "自动偷蛋",
		["Auto Treadmill"] = "自动跑步机",
		["Auto Upgrade Base"] = "自动升级基地",
		["Auto Upgrade Treadmill"] = "自动升级跑步机",
		["Auto Upgrades"] = "自动升级",
		["Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M"] = "基地 Lv2: 1K | Lv3: 1M | Lv4: 75M | 跑步机 Lv2: 15K | Lv3: 250K | Lv4: 5M",
		["Blacklist Selected"] = "加入黑名单",
		["Blacklisted Pets"] = "黑名单宠物",
		["Buy the next base upgrade whenever affordable."] = "有足够金币时自动购买下一级基地升级。",
		["Buy the next treadmill whenever affordable."] = "有足够金币时自动购买下一台跑步机。",
		["Clear Blacklist"] = "清空黑名单",
		["Configs"] = "配置",
		["Copy Discord Invite"] = "复制 Discord 邀请",
		["Costs"] = "费用",
		["Discord"] = "Discord",
		["Discord Webhook URL"] = "Discord Webhook 链接",
		["Drop the carried egg the moment a guard chases you."] = "守卫追赶时立刻丢下手中的蛋。",
		["ESP Eggs"] = "蛋 ESP",
		["ESP Guards"] = "守卫 ESP",
		["ESP Rare Eggs"] = "稀有蛋 ESP",
		["Eggs"] = "蛋",
		["Empty = all areas"] = "留空 = 所有区域",
		["Empty = all eggs"] = "留空 = 所有蛋",
		["Equip the best pets into your pen (game's Equip Best)."] = "将最佳宠物装备到围栏中（游戏内的 Equip Best）。",
		["Favorite Min Rarity"] = "收藏最低稀有度",
		["Favorite Mutation"] = "收藏变异",
		["Favorite Pets Now"] = "立即收藏宠物",
		["Game Auto Sell"] = "游戏自动出售",
		["Guard Chase Distance"] = "守卫追击距离",
		["Guard Safety"] = "守卫防护",
		["Guard Warning"] = "守卫警告",
		["Guards"] = "守卫",
		["Hatch growing eggs as soon as they're ready."] = "蛋一就绪就立刻孵化。",
		["Hop Speed"] = "跳跃速度",
		["Hops per second. Higher is faster but easier for the game to correct."] = "每秒跳跃次数。越高越快，但游戏更容易纠正。",
		["Interface"] = "界面",
		["Load"] = "加载",
		["Mark every area egg with name, rarity and distance."] = "为每个区域蛋标注名称、稀有度和距离。",
		["Mark guards with state and distance."] = "为守卫标注状态和距离。",
		["Menu Key"] = "菜单按键",
		["Minimum Rarity"] = "最低稀有度",
		["Movement"] = "移动方式",
		["Name"] = "名称",
		["Note"] = "说明",
		["Notify when a guard is chasing you."] = "守卫追赶你时发出通知。",
		["Only mark eggs at or above the threshold below."] = "仅标记达到或高于以下阈值的蛋。",
		["Only send for eggs at or above this rarity"] = "仅发送达到或高于此稀有度的蛋",
		["Paste your Discord webhook URL here"] = "在此粘贴你的 Discord Webhook 链接",
		["Pet Income Threshold"] = "宠物收益阈值",
		["Pet Max Rarity"] = "宠物最高稀有度",
		["Place Egg"] = "放置蛋",
		["Place Rule"] = "放置规则",
		["Place carried eggs into your pen when you get home."] = "回到基地时把携带的蛋放进围栏。",
		["Rare Threshold"] = "稀有阈值",
		["Remove Selected"] = "移除所选",
		["Restores everything this script changed and closes the menu"] = "还原脚本所做的一切更改并关闭菜单",
		["Save"] = "保存",
		["Saved"] = "已保存",
		["Select a pet, it will never be sold"] = "选择一只宠物，它将永不被出售",
		["Sell Blacklist"] = "出售黑名单",
		["Sell Pets Now"] = "立即出售宠物",
		["Sell Rule"] = "出售规则",
		["Sell pets at or below this rarity."] = "出售此稀有度及以下的宠物。",
		["Sell pets below this income. 0 or empty = disabled. e.g. 10M"] = "出售收益低于此值的宠物。0 或留空 = 关闭。例如 10M",
		["Send a Discord notification when an egg is stolen"] = "偷到蛋时发送 Discord 通知",
		["Send a test notification to verify the URL"] = "发送测试通知以验证链接",
		["Show Island"] = "显示灵动岛",
		["Steal"] = "偷蛋",
		["Steal Hop Size"] = "跳跃距离",
		["Steal Priority"] = "偷取优先级",
		["Steal eggs from areas, run them home and place them."] = "从区域偷蛋、带回基地并放置。",
		["Target Areas"] = "目标区域",
		["Target Eggs"] = "目标蛋",
		["Test Webhook"] = "测试 Webhook",
		["The game's own auto sell. Runs server side, works offline."] = "游戏自带的自动出售。服务端运行，离线也生效。",
		["The status pill at the top of the screen"] = "屏幕顶部的状态胶囊",
		["Train when idle. Pauses while carrying or stealing."] = "空闲时训练。携带或偷取时暂停。",
		["Treadmill"] = "跑步机",
		["UI Scale"] = "界面缩放",
		["Unavailable"] = "不可用",
		["Unload"] = "卸载",
		["Webhook Egg Steal"] = "偷蛋 Webhook",
		["Webhook Min Rarity"] = "Webhook 最低稀有度",
		["Your executor exposes no HTTP request function, so webhooks are disabled."] = "你的执行器未提供 HTTP 请求函数，Webhook 已禁用。",
		["Your executor has no file access, so configs are disabled."] = "你的执行器没有文件访问权限，配置已禁用。",
	},
}

SafeCall(function()
	WindUI:Localization({
		Enabled = true,
		Prefix = "loc:",
		DefaultLanguage = "en",
		Translations = TRANSLATIONS,
	})
end)
-- ============================================================ WINDOW

local Window = WindUI:CreateWindow({
	Title = HUB_NAME,
	Icon = "rbxassetid://" .. LOGO_ID,
	IconSize = 30,
	Author = "Supra",
	Folder = HUB_FOLDER,
	Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y),
	Theme = "Dark",
	Resizable = true,
	MinSize = Vector2.new(520, 380),
	SideBarWidth = IS_MOBILE and 150 or 190,
	HideSearchBar = false,
	Transparent = false,
	Radius = 16,
	ShadowTransparency = 0.35,
	ToggleKey = Enum.KeyCode.RightShift,
	Topbar = { Height = 46, ButtonsType = "Mac" },
	OpenButton = { Enabled = false },
})

Window:Tag({ Title = "v1.0", Color = ACCENT })

local MainGroup = Window:Section({ Title = "Main" })
local SystemGroup = Window:Section({ Title = "System" })

local Tabs = {
	Home = MainGroup:Tab({ Title = "Home", Icon = "layout-dashboard" }),
	Farm = MainGroup:Tab({ Title = "Farm", Icon = "egg-fried" }),
	Progress = MainGroup:Tab({ Title = "Progress", Icon = "trending-up" }),
	ESP = MainGroup:Tab({ Title = "ESP", Icon = "eye" }),
	Pets = MainGroup:Tab({ Title = "Pets", Icon = "paw-print" }),
	Webhook = SystemGroup:Tab({ Title = "Webhook", Icon = "webhook" }),
	Settings = SystemGroup:Tab({ Title = "Settings", Icon = "settings" }),
}

Island:AttachWindow(Window, WINDOW_SIZE)

-- ============================================================ GAME BRIDGE
-- Every endpoint below was read from the game's NETWORK_MAP registry. Calls
-- go through the client Network module when it exists, with a raw remote
-- fallback so a blocked require can't break the script.

local E = {
	AreaEggSnapshot = "Eggs: RequestAreaEggSnapshot",
	AreaEggCarry = "Eggs: RequestAreaEggCarry",
	AreaEggDrop = "Eggs: RequestAreaEggDrop",
	PlaceEgg = "Eggs: RequestPlaceEgg",
	EquipTool = "Eggs: RequestEquipTool",
	UnequipTool = "Eggs: RequestUnequipTool",
	HatchEgg = "Eggs: RequestHatchEgg",
	CompleteHatchEgg = "Eggs: RequestCompleteHatchEgg",

	AreaEggUpdated = "Eggs: AreaEggUpdated",
	AreaEggRemoved = "Eggs: AreaEggRemoved",
	AreaEggBatchUpdated = "Eggs: AreaEggBatchUpdated",
	AreaEggCarryState = "Eggs: AreaEggCarryState",
	AreaEggClaimFeedback = "Eggs: AreaEggClaimFeedback",

	BaseUpgrade = "Plots: RequestBaseUpgrade",
	OnBaseUpgraded = "Plots: OnBaseUpgraded",
	PlotState = "Plots: RequestState",

	TreadmillEquipStatic = "Treadmills: RequestEquipStatic",
	TreadmillUnequip = "Treadmills: RequestUnequip",
	TreadmillUpgrade = "Treadmills: RequestUpgrade",
	TreadmillActiveChanged = "Treadmills: ActiveTreadmillChanged",
	TreadmillSpeedGain = "Treadmills: SpeedGain",

	OfflineGetSummary = "OfflineAssets: GetSummary",
	OfflineRedeem = "OfflineAssets: Redeem",
	IndexClaimAll = "Index: RequestClaimAll",

	AssetRuntimeSnapshot = "ActiveAssets: RequestRuntimeSnapshot",
	AssetEquip = "ActiveAssets: RequestEquip",
	AssetUnequip = "ActiveAssets: RequestUnequip",
	MoneyUpdated = "ActiveAssets: MoneyUpdated",
	ItemUpdated = "ActiveAssets: ItemUpdated",

	SetFavorite = "AssetInventory: SetFavorite",
	SellAsset = "AssetInventory: SellAsset", -- RemoteEvent, fire-and-forget fallback
	RequestSell = "ActiveAssets: RequestSell", -- RemoteFunction(uid) -> ok
	GetAutoSell = "Backpack: GetAutoSellState",
	SetAutoSell = "Backpack: SetAutoSellState",

	GuardSpeedHitWarning = "Guards: SpeedHitWarning",
	GuardWakeUp = "Guards: WakeUp",
}

local Network
do
	local ok, mod = pcall(require, ReplicatedStorage.Library.Client.Network)
	if ok and mod then Network = mod end
end

local function FindRemote(name, class)
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj.Name == name and obj:IsA(class) then return obj end
	end
end

-- Network.Invoke / .Fire / .Fired are plain functions on the module, not
-- methods. Calling them with the module as the first argument (colon style)
-- makes the endpoint name land in the wrong slot and the module errors with
-- "Unable to assign property Name". Every call has to be dot style.
-- Passes every return through, not just the first. Several endpoints answer
-- (ok, reason) and the reason is the only way to tell "nothing to do" from
-- "call is wrong".
local function Invoke(name, ...)
	if Network then
		local r = table.pack(pcall(Network.Invoke, name, ...))
		if r[1] then return table.unpack(r, 2, r.n) end
	end
	local rf = FindRemote(name, "RemoteFunction")
	if rf then
		local r = table.pack(pcall(rf.InvokeServer, rf, ...))
		if r[1] then return table.unpack(r, 2, r.n) end
	end
	return nil
end

local function Fire(name, ...)
	if Network then
		-- Return on success, otherwise the raw fallback fires a second time.
		local ok = pcall(Network.Fire, name, ...)
		if ok then return end
	end
	local re = FindRemote(name, "RemoteEvent")
	if re then pcall(re.FireServer, re, ...) end
end

local function Fired(name, cb)
	if Network then
		local ev = Network.Fired(name)
		if ev and ev.Connect then
			local c = ev:Connect(cb)
			if c then return c end
		end
	end
	local re = FindRemote(name, "RemoteEvent")
	if re then return re.OnClientEvent:Connect(cb) end
end

local function BindEvent(name, cb)
	local c = Fired(name, cb)
	if c then Cleanup:Connection(c) end
end

local function TryRequire(path)
	local ok, mod = pcall(require, path)
	return ok and mod or nil
end

local SaveMod = TryRequire(ReplicatedStorage.Library.Client.Save)
local PlotCmds = TryRequire(ReplicatedStorage.Library.Client.PlotCmds)
local EggCmds = TryRequire(ReplicatedStorage.Library.Client.EggCmds)
local AssetCmds = TryRequire(ReplicatedStorage.Library.Client.AssetCmds)
local Bases = TryRequire(ReplicatedStorage.Directory.Bases)
local TreadmillsDir = TryRequire(ReplicatedStorage.Directory.Treadmills)

local AssetsDir
do
	local ok, mod = pcall(require, ReplicatedStorage.Directory.Assets)
	if ok and mod then AssetsDir = mod.Directory end
end

-- ============================================================ GAME HELPERS

local function GetSave()
	if not SaveMod then return nil end
	local ok, s = pcall(function() return SaveMod.Get(LocalPlayer, false) end)
	return ok and s or nil
end

local function EggConfig(cat)
	return AssetsDir and AssetsDir[cat]
end

local function EggRarityNum(cat)
	local c = EggConfig(cat)
	local r = c and c.Rarity
	return (r and r.RarityNumber) or 1
end

local function EggRarityId(cat)
	local c = EggConfig(cat)
	local r = c and c.Rarity
	return (r and (r._id or r.DisplayName)) or "Unknown"
end

local function EggName(cat)
	local c = EggConfig(cat)
	return (c and c.DisplayName) or cat or "?"
end

local function EggIncome(cat)
	local c = EggConfig(cat)
	return (c and c.EarningRate) or 0
end

-- Ordered rarity ladder, discovered from the asset directory at runtime.
local RarityLadder = {}
do
	local byNum = {}
	if AssetsDir then
		for _, c in pairs(AssetsDir) do
			local r = c and c.Rarity
			if r and r.RarityNumber then
				local n = r.RarityNumber
				if not byNum[n] then
					byNum[n] = r._id or r.DisplayName or ("Rarity " .. n)
				end
			end
		end
	end
	local nums = {}
	for n in pairs(byNum) do nums[#nums + 1] = n end
	table.sort(nums)
	for _, n in ipairs(nums) do RarityLadder[#RarityLadder + 1] = { n = n, name = byNum[n] } end
	if #RarityLadder == 0 then
		for _, n in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }) do
			RarityLadder[#RarityLadder + 1] = { n = #RarityLadder + 1, name = n }
		end
	end
end

local function RarityColor(num)
	local C = {
		[1] = Color3.fromRGB(170, 170, 170),
		[2] = Color3.fromRGB(83, 170, 98),
		[3] = Color3.fromRGB(7, 119, 255),
		[4] = Color3.fromRGB(255, 190, 60),
		[5] = Color3.fromRGB(255, 120, 60),
		[6] = Color3.fromRGB(170, 85, 255),
		[7] = Color3.fromRGB(255, 60, 255),
		[8] = Color3.fromRGB(120, 190, 255),
	}
	return C[num] or Color3.fromRGB(255, 255, 255)
end

local function FormatMoney(n)
	if type(n) ~= "number" then return "0" end
	local abs = math.abs(n)
	if abs >= 1e15 then return ("%.2fQ"):format(n / 1e15) end
	if abs >= 1e12 then return ("%.2fT"):format(n / 1e12) end
	if abs >= 1e9 then return ("%.2fB"):format(n / 1e9) end
	if abs >= 1e6 then return ("%.2fM"):format(n / 1e6) end
	if abs >= 1e3 then return ("%.1fK"):format(n / 1e3) end
	return ("%d"):format(math.floor(n))
end

-- Parses "10M", "100K", "1B" or a plain number. Returns nil when unparseable.
local function ParseMoney(s)
	if not s then return nil end
	local str = s:gsub(",", ""):gsub("%s+", ""):upper()
	if str == "" or str == "0" then return 0 end
	local mult = 1
	local num = str:match("^([%d%.]+)([KMBQ]?)$")
	if not num then return nil end
	local prefix = str:match("[KMBQ]$")
	if prefix == "K" then mult = 1e3 elseif prefix == "M" then mult = 1e6
	elseif prefix == "B" then mult = 1e9 elseif prefix == "Q" then mult = 1e12 end
	local v = tonumber(num)
	if not v then return nil end
	return v * mult
end

-- ============================================================ CHARACTER / PLOT

local function MyHRP()
	local _, _, hrp = GetCharacter()
	return hrp
end

local function MySlot()
	if PlotCmds then
		local ok, slot = pcall(function() return PlotCmds.GetMySlot() end)
		if ok and slot then return slot end
	end
	-- fallback: ask the server for the owner map and find ourselves
	local res = Invoke(E.PlotState)
	if type(res) == "table" and type(res.OwnersBySlot) == "table" then
		for slot, uid in pairs(res.OwnersBySlot) do
			if tonumber(uid) == LocalPlayer.UserId then return tonumber(slot) end
		end
	end
	return nil
end

local function MyPlot()
	local slot = MySlot()
	if not slot then return nil end
	return Workspace.Plots:FindFirstChild(tostring(slot))
end

local function MyPlotPoint()
	local plot = MyPlot()
	if plot then
		local cp = plot:FindFirstChild("CenterPoint")
		if cp and cp:IsA("BasePart") then return cp.Position end
		local sp = plot:FindFirstChild("SpawnPoint")
		if sp and sp:IsA("BasePart") then return sp.Position end
	end
	return nil
end

local function InMyPlot(pos)
	if not pos then return false end
	if PlotCmds then
		local ok, inside = pcall(function()
			return PlotCmds.IsWorldPositionWithinLocalPlotBounds(pos)
		end)
		if ok and inside then return true end
	end
	local point = MyPlotPoint()
	return point ~= nil and (pos - point).Magnitude <= 22
end

local function IsTrapped()
	local _, _, hrp = GetCharacter()
	if not hrp then return false end
	local char = hrp.Parent
	return char and char:GetAttribute("IsTrapped") == true
end

-- ============================================================ MOVEMENT
-- Hop mode is the default and is driven by its own fast loop (the farm tick
-- is too slow to hop smoothly). If the game's integrity check keeps undoing
-- the hops (no net movement), it auto-falls back to walking for a few seconds
-- then tries hopping again.

local MoveCfg = { Mode = "Hop", HopSize = 30, HopRate = 40 }

local Movement = {
	Active = false,
	Target = nil,
	Within = 3,
	Clock = 0,
	ProgressCheck = 0,
	LastPos = nil,
	FallbackWalk = false,
}

function Movement:Go(point, within)
	if not point then return end
	if self.Active and self.Target and (self.Target - point).Magnitude < 5 then
		self.Within = within or self.Within
		return
	end
	self.Target = point
	self.Within = within or 3
	self.Active = true
	self.Clock = 0
	self.ProgressCheck = os.clock()
	self.LastPos = nil
end

function Movement:Stop()
	self.Active = false
	self.Target = nil
end

-- Ask the world, not the mover. Callers re-issue Go every tick, which used to
-- reset the mover's arrival flag one line before it was read, so the farm
-- could never leave MovingToEgg.
local function AtPoint(point, within)
	local hrp = MyHRP()
	if not (hrp and point) then return false end
	return (point - hrp.Position).Magnitude <= (within or 4)
end

local function MoverTick(dt)
	if not Movement.Active then return end
	local _, hum, hrp = GetCharacter()
	if not hum or not hrp or hum.Health <= 0 then
		Movement:Stop()
		return
	end
	if IsTrapped() then return end

	local target = Movement.Target
	local delta = target - hrp.Position
	local dist = delta.Magnitude
	if dist <= Movement.Within then
		Movement:Stop()
		return
	end

	local effMode = MoveCfg.Mode
	if Movement.FallbackWalk then effMode = "Walk" end

	if effMode == "Hop" then
		local interval = 1 / math.max(MoveCfg.HopRate, 1)
		Movement.Clock = Movement.Clock + dt
		while Movement.Clock >= interval do
			Movement.Clock = Movement.Clock - interval
			local step = math.min(dist, MoveCfg.HopSize)
			hrp.CFrame = hrp.CFrame + delta.Unit * step + Vector3.new(0, 1, 0)
			dist = (target - hrp.Position).Magnitude
			if dist <= Movement.Within then
				Movement:Stop()
				return
			end
		end

		if os.clock() - Movement.ProgressCheck > 1.5 then
			local moved = hrp.Position
			if Movement.LastPos then
				local net = (moved - Movement.LastPos).Magnitude
				if net < 5 then
					Movement.FallbackWalk = true
					task.delay(3, function() Movement.FallbackWalk = false end)
				end
			end
			Movement.LastPos = moved
			Movement.ProgressCheck = os.clock()
		end
	else
		hum:MoveTo(target)
		hum.AutoRotate = true
	end
end

-- ============================================================ EGG STORE
-- Refreshes the area egg snapshot on demand and follows the update events so
-- the farm and the ESP always see live records.

local EggStore = { ByUid = {}, List = {}, LastRefresh = 0, Ready = false }

local function ApplyAreaRecords(records)
	EggStore.ByUid = {}
	for _, rec in ipairs(records) do
		EggStore.ByUid[rec.Uid] = rec
	end
	EggStore.List = records
	EggStore.Ready = true
end

function EggStore:Refresh(force)
	local now = os.clock()
	if not force and (now - self.LastRefresh) < 1.2 then return self.Ready end
	self.LastRefresh = now
	local res = Invoke(E.AreaEggSnapshot)
	if type(res) ~= "table" then return self.Ready end
	local records = res.Records or res
	if type(records) ~= "table" then return self.Ready end
	ApplyAreaRecords(records)
	return true
end

function EggStore:Get(uid)
	return self.ByUid[uid]
end

BindEvent(E.AreaEggUpdated, function(rec)
	if rec and rec.Uid then
		EggStore.ByUid[rec.Uid] = rec
		EggStore.List = {}
		for _, r in pairs(EggStore.ByUid) do EggStore.List[#EggStore.List + 1] = r end
	end
end)

BindEvent(E.AreaEggRemoved, function(uid)
	if uid then
		EggStore.ByUid[uid] = nil
		EggStore.List = {}
		for _, r in pairs(EggStore.ByUid) do EggStore.List[#EggStore.List + 1] = r end
	end
end)

-- ============================================================ CARRY STATE

local Carry = {
	IsCarrying = false,
	Uid = nil,
	AreaId = nil,
	Category = nil,
	Since = 0,
}

BindEvent(E.AreaEggCarryState, function(state)
	if type(state) ~= "table" then return end
	Carry.IsCarrying = state.IsCarrying == true
	Carry.Uid = state.Uid
	Carry.AreaId = state.AreaId
	Carry.Category = state.AssetCategory
	Carry.Since = os.clock()
end)

local function IsCarrying()
	return Carry.IsCarrying
end

-- ============================================================ GUARD MONITOR

local GuardState = {
	Chasing = false,
	Guard = nil,
	Distance = math.huge,
	LastWarnAt = 0,
	LastDropAt = 0,
}

local GuardCfg = {
	Warning = false,
	AutoDrop = false,
	Distance = 25,
}

local function GuardModels()
	local folder = Workspace:FindFirstChild("__OBJECTS")
		and Workspace.__OBJECTS:FindFirstChild("Areas")
		and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
	if not folder then return {} end
	local out = {}
	for _, area in ipairs(folder:GetChildren()) do
		local g = area:FindFirstChild("Guard")
		if g and g:IsA("Model") then out[#out + 1] = g end
	end
	return out
end

local function ScanGuards()
	local uidStr = tostring(LocalPlayer.UserId)
	local hrp = MyHRP()
	local chasing, bestG, bestD = false, nil, math.huge

	for _, g in ipairs(GuardModels()) do
		local root = g:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local dist = hrp and (root.Position - hrp.Position).Magnitude or math.huge
			local state = g:GetAttribute("GuardState")
			local target = g:GetAttribute("TargetPlayer")
			local wakeTarget = g:GetAttribute("WakeTargetPlayer")
			local hum = g:FindFirstChildOfClass("Humanoid")
			local moving = hum and hum.WalkSpeed > 1 or false

			local attrChase = (state == "Chase" or state == "Waking" or state == "EggRetrieval")
				and (target == uidStr or wakeTarget == uidStr)
			local proxChase = dist < GuardCfg.Distance and moving

			if attrChase or proxChase then
				chasing = true
				if dist < bestD then bestD, bestG = dist, g end
			end
		end
	end

	GuardState.Chasing = chasing
	GuardState.Guard = bestG
	GuardState.Distance = bestD
end

BindEvent(E.GuardSpeedHitWarning, function()
	if not GuardCfg.Warning then return end
	Notify("Guard", "Speed hit incoming! Move!", 2, "triangle-alert")
end)

BindEvent(E.GuardWakeUp, function()
	if GuardCfg.Warning and not GuardState.Chasing then
		Notify("Guard", "A guard woke up.", 2, "eye")
	end
end)

-- ============================================================ WEBHOOK

local WebhookCfg = {
	Url = "",
	OnSteal = false,
	MinRarity = 0, -- 0 = every rarity
}

-- Executors all expose this under a different name.
local httprequest = (syn and syn.request) or (http and http.request) or http_request or request

local WEBHOOK_PATTERN = "^https://[%w%.]*discord%.?a?p?p?%.com/api/webhooks/%d+/[%w%-_]+$"

local function WebhookReady()
	return httprequest ~= nil and WebhookCfg.Url ~= ""
end

-- Fire and forget on its own thread: a webhook round trip is ~200ms and the
-- farm tick must not wait on Discord.
local function SendWebhook(embed)
	if not WebhookReady() then return end
	local url = WebhookCfg.Url
	task.spawn(function()
		SafeCall(function()
			httprequest({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					username = "Supra | " .. HUB_NAME,
					avatar_url = "https://raw.githubusercontent.com/LogicalGoy/WyndUil/main/logo.png",
					embeds = { embed },
				}),
			})
		end)
	end)
end

local function StealEmbed(rec)
	local cat = rec and rec.AssetCategory
	local rar = EggRarityNum(cat)
	local s = GetSave()
	local colour = RarityColor(rar)
	return {
		title = "Egg Stolen",
		color = math.floor(colour.R * 255) * 65536
			+ math.floor(colour.G * 255) * 256
			+ math.floor(colour.B * 255),
		fields = {
			{ name = "Egg", value = EggName(cat), inline = true },
			{ name = "Rarity", value = EggRarityId(cat), inline = true },
			{ name = "Area", value = tostring(rec and rec.AreaId or "?"), inline = true },
			{ name = "Income", value = FormatMoney(EggIncome(cat)) .. "/s", inline = true },
			{ name = "Money", value = FormatMoney(s and s.Money or 0), inline = true },
			{ name = "Player", value = LocalPlayer.Name, inline = true },
		},
		footer = { text = HUB_NAME .. " | " .. os.date("%X") },
	}
end

local function NotifySteal(rec)
	if not WebhookCfg.OnSteal or not rec then return end
	if WebhookCfg.MinRarity > 0 and EggRarityNum(rec.AssetCategory) < WebhookCfg.MinRarity then
		return
	end
	SendWebhook(StealEmbed(rec))
end

-- ============================================================ FARM

local FarmCfg = {
	On = false,
	MinRarity = 0, -- 0 = disabled
	Priority = "Rarity", -- Rarity | Closest | Income
	Areas = {}, -- set of area ids; empty = all
	Eggs = {}, -- set of egg categories; empty = all
	AutoPlace = false,
	PlaceRule = "Always", -- Always | Full
	AutoHatch = false,
}

local Farm = {
	State = "Idle",
	Target = nil,
	StateChangedAt = 0,
	ActionAt = 0,
	FailCount = 0,
}

local function FarmTargetOk(rec)
	if not rec then return false end
	if rec.State ~= "Slot" then return false end
	if FarmCfg.Areas[rec.AreaId] == false then return false end
	if FarmCfg.Eggs[rec.AssetCategory] == false then return false end
	if FarmCfg.MinRarity > 0 and EggRarityNum(rec.AssetCategory) < FarmCfg.MinRarity then return false end
	return true
end

local function FindStealTarget()
	EggStore:Refresh()
	local hrp = MyHRP()
	local best, bestScore = nil, math.huge
	for _, rec in pairs(EggStore.ByUid) do
		if FarmTargetOk(rec) and rec.BottomCFrame then
			local dist = hrp and (rec.BottomCFrame.Position - hrp.Position).Magnitude or math.huge
			local score
			if FarmCfg.Priority == "Closest" then
				score = dist
			elseif FarmCfg.Priority == "Income" then
				score = -EggIncome(rec.AssetCategory)
			else
				score = -EggRarityNum(rec.AssetCategory) * 1000 + dist
			end
			if score < bestScore then best, bestScore = rec, score end
		end
	end
	return best
end

-- Every egg we own, placed or not. The save's EggInventory entry carries only
-- the egg's looks and never a Placement field, so the old checks against
-- v.Placement matched nothing at all.
--
-- ponytail: nothing client-side distinguishes placed from unplaced -- only the
-- server knows, and it answers "Egg is not placed" when asked to hatch one.
-- Hatching is unaffected (we ask about every egg and the ready ones answer),
-- but the pen count below is an upper bound.
local function OwnedEggs()
	if not EggCmds then return {} end
	local ok, recs = pcall(EggCmds.GetOwnerRuntimeRecords, LocalPlayer.UserId)
	return (ok and type(recs) == "table") and recs or {}
end

local function PenFull()
	local s = GetSave()
	if not s then return false end
	local capacity = Bases and Bases.GetAssetEquipCapacity and Bases.GetAssetEquipCapacity(s.BaseUpgradeLevel) or 10
	local owned = 0
	for _ in pairs(OwnedEggs()) do owned = owned + 1 end
	return owned >= capacity
end

local function ShouldPlaceNow()
	if not FarmCfg.AutoPlace then return false end
	if FarmCfg.PlaceRule == "Always" then return true end
	return PenFull()
end

local function DropHeldEgg(reason)
	if not IsCarrying() then return true end
	local ok = Invoke(E.AreaEggDrop, { Reason = reason or "PlayerRequest" })
	return ok == true
end

-- There is not one shared prompt part -- there are 47 of them, one per area
-- egg, each holding its own CarryAreaEgg. FindFirstChild("SmartPromptPart")
-- returned an arbitrary one, usually hundreds of studs away and disabled,
-- which is why firing the prompt almost never did anything. Search them all
-- and take the nearest enabled one that is actually in range.
--
-- The hatch prompt lives on the same kind of part but is named plainly
-- "ProximityPrompt", so match on ActionText rather than the child's name.
local function NearestPrompt(action)
	local hrp = MyHRP()
	if not hrp then return nil end
	local best, bestDist

	for _, part in ipairs(Workspace:GetChildren()) do
		if part.Name == "SmartPromptPart" and part:IsA("BasePart") then
			local dist = (part.Position - hrp.Position).Magnitude
			for _, prompt in ipairs(part:GetChildren()) do
				if prompt:IsA("ProximityPrompt")
					and prompt.Enabled
					and string.find(prompt.ActionText or "", action, 1, true)
					and dist <= (prompt.MaxActivationDistance or 8)
					and (not bestDist or dist < bestDist)
				then
					best, bestDist = prompt, dist
				end
			end
		end
	end
	return best
end

local function FirePrompt(prompt)
	if not prompt then return false end

	-- The steal prompt ships with a 1.2s hold. Guards stand right on top of
	-- these eggs, so waiting it out is a free hit. HoldDuration is client-side
	-- only; zeroing it makes the trigger fire the instant we ask.
	pcall(function() prompt.HoldDuration = 0 end)

	if typeof(fireproximityprompt) == "function" then
		local ok = pcall(fireproximityprompt, prompt, 1)
		if not ok then pcall(fireproximityprompt, prompt) end
		return true
	end
	return false
end

local function FireCarryPrompt()
	return FirePrompt(NearestPrompt("Steal"))
end

local function TryCarry(rec)
	local uid = rec.Uid
	-- FirstArea eggs (Forest tutorial) require the slot key, otherwise the
	-- server answers "Egg not found". Matches the game's own client exactly.
	local key
	if string.find(uid, "FirstAreaEgg_", 1, true) == 1 then
		key = rec.AreaId .. ":" .. (rec.NestId or "")
	end
	local ok, err = Invoke(E.AreaEggCarry, { Uid = uid, FirstAreaSlotKey = key })
	if ok == true then return true end

	if type(err) == "string" then
		-- Positional rejections mean we simply have not walked in far enough
		-- yet. Keep the target and let the mover carry on instead of spending
		-- a retry and giving up on a perfectly good egg.
		if err:find("gameplay area") or err:find("too far") then
			Island:Detail("moving closer")
			return false, true
		end
		Notify("Farm", err, 2, "triangle-alert")
	end
	return false
end

-- LocalCFrame is plot-local. Sunflower spacing: the golden angle spreads points evenly instead of
-- stacking them on a few rings, and sqrt growth keeps the density constant as
-- the pen fills. A fixed ring pattern kept landing on eggs already there and
-- the server answered "Egg is too close to another egg!".
local PlaceSpiral = 0
local PlaceWarnAt = 0 -- a full pen must not toast once per egg per tick

local function PlaceSpot(n)
	local angle = n * 2.3999632 -- golden angle in radians
	local radius = math.min(3 + math.sqrt(n) * 2.4, 18)
	return CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function TryPlace(uid)
	if not uid then return false end

	local lastErr
	-- A rejected spot is not a rejected egg, so walk the spiral and retry
	-- rather than burning the whole attempt on one unlucky position.
	for _ = 1, 12 do
		PlaceSpiral = PlaceSpiral + 1
		local spot = PlaceSpot(PlaceSpiral)

		local ok, placed, err
		if EggCmds and EggCmds.RequestPlaceEgg then
			ok, placed, err = pcall(EggCmds.RequestPlaceEgg, uid, spot)
		end
		if not ok then
			placed, err = Invoke(E.PlaceEgg, { Uid = uid, LocalCFrame = spot })
		end

		if placed == true then return true end
		lastErr = err

		-- Only a spacing complaint is worth another spot; anything else
		-- (pen full, egg not held, bad uid) will fail identically forever.
		if type(err) ~= "string" or not err:find("too close") then break end
	end

	if type(lastErr) == "string" and os.clock() - PlaceWarnAt > 15 then
		PlaceWarnAt = os.clock()
		Notify("Farm", "Place failed: " .. lastErr, 3, "triangle-alert")
	end
	return false
end

local HatchCooldown = {}

-- Workspace.PlacedEggRenders holds one model per placed egg, named
-- "<ownerUserId>_<eggUid>". It is the only client-side source that actually
-- knows what is in the pen -- the save and the runtime records list every egg
-- you own, placed or not.
local function PlacedEggUids()
	local prefix = tostring(LocalPlayer.UserId) .. "_"
	local set = {}
	for _, folder in ipairs(Workspace:GetChildren()) do
		if folder.Name == "PlacedEggRenders" then
			for _, model in ipairs(folder:GetChildren()) do
				if string.find(model.Name, prefix, 1, true) == 1 then
					set[string.sub(model.Name, #prefix + 1)] = true
				end
			end
		end
	end
	return set
end

-- Readiness comes from the game's own IsLocalEggReady. Prompt first, because
-- that is what a real player does; the remote is the fallback for when we are
-- out of range of the pen.
local function AutoHatchTick()
	if not FarmCfg.AutoHatch then return end

	local uidList = {}
	for uid in pairs(OwnedEggs()) do
		local ok, ready = pcall(EggCmds.IsLocalEggReady, uid)
		if ok and ready then uidList[#uidList + 1] = uid end
	end
	if #uidList == 0 then return end

	local prompt = NearestPrompt("Hatch")
	if prompt then FirePrompt(prompt) end

	for _, uid in ipairs(uidList) do
		if not HatchCooldown[uid] or os.clock() - HatchCooldown[uid] > 8 then
			HatchCooldown[uid] = os.clock()
			if Invoke(E.HatchEgg, uid) == true then
				task.delay(0.4, function() Invoke(E.CompleteHatchEgg, uid) end)
			end
		end
	end
end

-- Anything we own that is not rendered in the pen is sitting in the inventory
-- doing nothing. The farm's Placing state only ever handled an egg carried in
-- from an area, so inventory eggs were never placed at all.
local PlaceCooldown = {}

local function AutoPlaceTick()
	if not FarmCfg.AutoPlace then return end
	local placed = PlacedEggUids()
	for uid in pairs(OwnedEggs()) do
		if not placed[uid] then
			if not PlaceCooldown[uid] or os.clock() - PlaceCooldown[uid] > 5 then
				PlaceCooldown[uid] = os.clock()
				if TryPlace(uid) then
					Island:Push("Placed egg", 2)
					return -- one per tick, so the pen fills in a visible order
				end
			end
		end
	end
end

-- The island's detail line is the egg we are working on. It used to be set on
-- pickup and never cleared, so it kept naming a long-gone target underneath
-- "no eggs". Route every status change through here and it stays honest.
local function FarmStatus(text, rec)
	Island:Status(text)
	Island:Detail(rec and EggName(rec.AssetCategory) or nil)
end

-- State machine. Cheap enough to run on a fast tick; never per-frame.
local function FarmSetState(name)
	if Farm.State ~= name then
		Farm.StateChangedAt = os.clock()
	end
	Farm.State = name
end

-- Its own function so arriving at an egg can grab in the same tick instead of
-- waiting for the next one. A guard is usually standing on the thing.
local function DoCarry(now)
	local target = Farm.Target
	if not target then FarmSetState("Idle") return end

	local function Grabbed()
		Farm.ActionAt = now
		FarmSetState("RunningHome")
		FarmStatus("Carrying home", target)
		NotifySteal(target)
		-- Start hopping out immediately rather than idling here for a tick.
		local point = MyPlotPoint()
		if point then Movement:Go(point, 6) end
	end

	-- Prompt first, remote second. The prompt is the path the real client
	-- takes; the remote stays as the fallback for when we are in range but
	-- the prompt has not enabled yet.
	FireCarryPrompt()

	if IsCarrying() then
		Grabbed()
		return
	end

	local carried, positional = TryCarry(target)
	if carried then
		Grabbed()
	elseif positional then
		-- Walk in further and try again; this is not a failure.
		FarmSetState("MovingToEgg")
	else
		Farm.FailCount = Farm.FailCount + 1
		Farm.ActionAt = now
		Farm.State = Farm.FailCount >= 3 and "Idle" or "MovingToEgg"
	end
end

local function FarmTick()
	if not FarmCfg.On then
		if Farm.State ~= "Idle" then
			Movement:Stop()
			Farm.Target = nil
		end
		FarmSetState("Idle")
		return
	end

	local now = os.clock()

	if IsCarrying() then
		-- Guard safety first: if a guard is chasing, drop the egg.
		if GuardCfg.AutoDrop and GuardState.Chasing and now - GuardState.LastDropAt > 1.5 then
			GuardState.LastDropAt = now
			DropHeldEgg("PlayerRequest")
			FarmSetState("Idle")
			return
		end
		if now - Carry.Since < 0.15 then return end -- one beat for the carry to settle

		-- Run home and place.
		if FarmCfg.AutoPlace then
			local point = MyPlotPoint()
			if point then
				if InMyPlot(MyHRP() and MyHRP().Position) then
					FarmSetState("Placing")
				else
					FarmSetState("RunningHome")
				end
			end
		else
			FarmSetState("Idle") -- carrying but not auto-placing: hold
			return
		end
	end

	local state = Farm.State

	-- A dropped/lost egg can leave run-home/place states behind; recover.
	if not IsCarrying() and (state == "RunningHome" or state == "Placing" or state == "Holding") then
		FarmSetState("Idle")
		Farm.Target = nil
		FarmStatus("Farm: idle", nil)
		Farm.ActionAt = now
		return
	end

	if state == "Idle" then
		if now - Farm.ActionAt < 1.2 then return end
		local target = FindStealTarget()
		if not target then
			FarmStatus("Farm: no eggs", nil)
			return
		end
		Farm.Target = target
		FarmSetState("MovingToEgg")
		Farm.FailCount = 0
		FarmStatus("Stealing", target)
		return
	end

	if state == "MovingToEgg" then
		local target = Farm.Target
		if not target then FarmSetState("Idle") return end
		-- target vanished or got taken
		local rec = EggStore:Get(target.Uid)
		if not rec or rec.State ~= "Slot" then
			FarmSetState("Idle")
			Farm.ActionAt = now
			return
		end
		local pos = target.BottomCFrame and target.BottomCFrame.Position
		if not pos then FarmSetState("Idle") return end
		if AtPoint(pos, 5) then
			Movement:Stop()
			FarmSetState("Carrying")
			DoCarry(now)
			return
		end
		Movement:Go(pos, 3.5)
		if now - Farm.StateChangedAt > 25 then
			Farm.FailCount = Farm.FailCount + 1
			Farm.ActionAt = now
			Movement:Stop()
			FarmSetState(Farm.FailCount >= 3 and "Idle" or "MovingToEgg")
			if Farm.FailCount >= 3 then Notify("Farm", "Could not reach egg.", 2, "triangle-alert") end
		end
		return
	end

	if state == "Carrying" then
		DoCarry(now)
		return
	end

	if state == "RunningHome" then
		local point = MyPlotPoint()
		if point then
			local hrp = MyHRP()
			if hrp and InMyPlot(hrp.Position) then
				if ShouldPlaceNow() then
					FarmSetState("Placing")
				else
					FarmSetState("Holding")
				end
				return
			end
			Movement:Go(point, 6)
			if now - Farm.StateChangedAt > 30 then
				Movement:Stop()
				DropHeldEgg("PlayerRequest")
				FarmSetState("Idle")
				Farm.ActionAt = now
			end
		end
		return
	end

	if state == "Placing" then
		-- The carry state is the authority on what we are actually holding.
		-- Farm.Target is the area record we set out for, which is stale the
		-- moment the server hands us a different egg or the target is dropped.
		local uid = Carry.Uid or (Farm.Target and Farm.Target.Uid)
		if uid and TryPlace(uid) then
			FarmSetState("Idle")
			Farm.ActionAt = now
			Island:Push("Placed " .. EggName(Farm.Target and Farm.Target.AssetCategory or Carry.Category), 2)
		else
			Farm.FailCount = Farm.FailCount + 1
			if Farm.FailCount >= 3 then
				DropHeldEgg("PlayerRequest")
				FarmSetState("Idle")
				Farm.ActionAt = now
			end
		end
		return
	end

	if state == "Holding" then
		-- carry but rule says only place when full; wait at the pen.
		if ShouldPlaceNow() then FarmSetState("Placing") end
		return
	end
end

-- ============================================================ TREADMILL

local TreadmillCfg = { On = false }
local Treadmill = { Active = false, EquipAt = 0 }

BindEvent(E.TreadmillActiveChanged, function(player, active)
	if player == LocalPlayer then
		Treadmill.Active = active == true
	end
end)

local function MyTreadmillBottom()
	local plot = MyPlot()
	if not plot then return nil end
	local bottom = plot:FindFirstChild("TreadmillBottom")
	return bottom and bottom:IsA("BasePart") and bottom or nil
end

local function ExitTreadmill()
	if not Treadmill.Active then return true end
	Invoke(E.TreadmillUnequip)
	Treadmill.Active = false
	return true
end

local function TreadmillTick()
	if not TreadmillCfg.On then return end
	-- Don't train while the farm is mid-run or while carrying.
	if IsCarrying() or (FarmCfg.On and Farm.State ~= "Idle") then
		if Treadmill.Active then ExitTreadmill() end
		return
	end

	local bottom = MyTreadmillBottom()
	if not bottom then return end
	local hrp = MyHRP()
	if not hrp then return end

	if Treadmill.Active then
		Island:Status("Treadmill")
		Island:Detail("SpeedPower " .. tostring(GetSave() and GetSave().SpeedPower or 0))
		return
	end

	if (hrp.Position - bottom.Position).Magnitude <= 7 and os.clock() - Treadmill.EquipAt > 2 then
		Treadmill.EquipAt = os.clock()
		if Invoke(E.TreadmillEquipStatic) == true then
			Treadmill.Active = true
			Island:Status("Treadmill")
		end
		return
	end

	if AtPoint(bottom.Position, 7) then
		Movement:Stop()
		Treadmill.EquipAt = 0
		return
	end
	Movement:Go(bottom.Position, 6)
end

-- ============================================================ PROGRESS

local ProgressCfg = {
	Base = false,
	Treadmill = false,
	Offline = false,
	Index = false,
}

local function BaseUpgradeTick()
	if not ProgressCfg.Base then return end
	local s = GetSave()
	if not s then return end
	local level = s.BaseUpgradeLevel
	local nextCfg = Bases and Bases.BASES and Bases.BASES[level + 1]
	if not nextCfg then return end
	if s.Money >= nextCfg.Cost then
		Fire(E.BaseUpgrade)
		Island:Push("Base -> Lv " .. tostring(level + 1), 2)
	end
end

local function TreadmillUpgradeTick()
	if not ProgressCfg.Treadmill then return end
	local s = GetSave()
	if not s then return end
	local nextCfg = TreadmillsDir and TreadmillsDir.GetByUpgradeLevel
		and TreadmillsDir.GetByUpgradeLevel(s.TreadmillUpgradeLevel + 1)
	if not nextCfg then return end
	if s.Money >= (nextCfg.Price or math.huge) then
		if Invoke(E.TreadmillUpgrade, nextCfg._id) == true then
			Island:Push("Treadmill -> " .. tostring(nextCfg._id), 2)
		end
	end
end

local function OfflineClaimTick()
	if not ProgressCfg.Offline then return end
	local summary = Invoke(E.OfflineGetSummary)
	if type(summary) ~= "table" then return end
	if (summary.ClaimableAmount or 0) > 0 then
		Invoke(E.OfflineRedeem)
		Island:Push("Claimed " .. FormatMoney(summary.ClaimableAmount) .. " offline", 2)
	end
end

-- Verified live: a RemoteFunction returning (ok, reason). The old Fire fallback
-- was chasing a RemoteEvent that does not exist, so a "nothing to claim" answer
-- looked like a failed call.
local function IndexClaimTick()
	if not ProgressCfg.Index then return end
	local ok, reason = Invoke(E.IndexClaimAll)
	if ok == true then
		Island:Push("Claimed index rewards", 2)
	elseif type(reason) == "string" and not reason:find("No index rewards") then
		Notify("Progress", reason, 2, "triangle-alert")
	end
end

-- ============================================================ PETS

local PetCfg = {
	AutoFavorite = false,
	FavMinRarity = 0,
	FavMutation = "", -- empty = any

	AutoSell = false,
	SellRule = "Both", -- Rarity | Income | Both
	MaxRarity = 0, -- 0 = disabled
	IncomeThreshold = 0, -- 0 = disabled
	Blacklist = {}, -- uid -> display name

	EquipBest = false,
}

local EquipBestLast = 0

local function OwnedPets()
	local out = {}
	local me = LocalPlayer.UserId
	local function Add(uid, itemData)
		if not uid or not itemData or out[uid] then return end
		out[uid] = { UID = uid, ItemData = itemData }
	end
	-- Direct runtime snapshot is the reliable source in an executor context.
	local res = Invoke(E.AssetRuntimeSnapshot)
	if type(res) == "table" then
		for _, owner in ipairs(res) do
			if owner and owner.OwnerUserId == me and type(owner.Records) == "table" then
				for uid, rec in pairs(owner.Records) do
					if rec and rec.ItemData then Add(uid, rec.ItemData) end
				end
			end
		end
	end
	if AssetCmds then
		local ok, recs = pcall(function() return AssetCmds.GetOwnerRuntimeRecords(me) end)
		if ok and recs then
			for uid, rec in pairs(recs) do
				Add(uid, rec.ItemData)
			end
		end
	end
	local s = GetSave()
	if s and type(s.Inventory) == "table" then
		for uid, item in pairs(s.Inventory) do
			if type(item) == "table" then
				Add(uid, item.ItemData or item)
			end
		end
	end
	return out
end

local function PetRarity(ItemData)
	return EggRarityNum(ItemData.Category)
end

local function PetIncome(ItemData)
	return ItemData.GeneratedMoney or EggIncome(ItemData.Category)
end

local function PetMutations(ItemData)
	return ItemData.Mutations or {}
end

local function PetMatchesFavorite(ItemData)
	if PetCfg.FavMinRarity > 0 and PetRarity(ItemData) < PetCfg.FavMinRarity then return false end
	if PetCfg.FavMutation ~= "" then
		local found = false
		for _, m in ipairs(PetMutations(ItemData)) do
			if m == PetCfg.FavMutation then found = true break end
		end
		if not found then return false end
	end
	return true
end

local function PetMatchesSell(ItemData, uid)
	if PetCfg.Blacklist[uid] then return false end
	if ItemData.IsFavorite == true then return false end
	if PetCfg.MaxRarity > 0 and PetRarity(ItemData) > PetCfg.MaxRarity then return false end
	if PetCfg.IncomeThreshold > 0 and PetIncome(ItemData) >= PetCfg.IncomeThreshold then return false end
	if PetCfg.SellRule == "Rarity" then
		return PetCfg.MaxRarity > 0
	elseif PetCfg.SellRule == "Income" then
		return PetCfg.IncomeThreshold > 0
	end
	return (PetCfg.MaxRarity > 0 or PetCfg.IncomeThreshold > 0)
end

local function FavoritePet(uid)
	Fire(E.SetFavorite, uid, true)
end

-- Verified live: ActiveAssets: RequestSell is a RemoteFunction taking a plain
-- uid string and answering with a success bool. Passing a table trips the
-- server's assert, which is how the old guessed shape was silently doing
-- nothing. AssetInventory: SellAsset is a RemoteEvent covering backpack items
-- the runtime snapshot does not own, so it stays as a fire-and-forget fallback.
local function SellPet(uid)
	if Invoke(E.RequestSell, uid) == true then return true end
	Fire(E.SellAsset, uid)
	return false
end

-- The game ships its own server-side auto-sell, keyed by rarity id. Verified
-- live: SetAutoSellState takes a { [RarityId] = true } map and answers
-- (ok, payload). It keeps selling while you are offline, which no client loop
-- can do, so it is the better tool whenever plain rarity filtering is enough.
local function PushNativeAutoSell(set)
	local ok = Invoke(E.SetAutoSell, set or {})
	return ok == true
end

local function FavoriteTick()
	if not PetCfg.AutoFavorite then return end
	for uid, pet in pairs(OwnedPets()) do
		if pet.ItemData.IsFavorite ~= true and PetMatchesFavorite(pet.ItemData) then
			FavoritePet(uid)
		end
	end
end

local function SellTick()
	if not PetCfg.AutoSell then return end
	for uid, pet in pairs(OwnedPets()) do
		if PetMatchesSell(pet.ItemData, uid) then
			SellPet(uid)
		end
	end
end

local function FavoriteNow()
	local n = 0
	for uid, pet in pairs(OwnedPets()) do
		if pet.ItemData.IsFavorite ~= true and PetMatchesFavorite(pet.ItemData) then
			FavoritePet(uid)
			n = n + 1
		end
	end
	Notify("Pets", ("Favorited %d pet%s."):format(n, n == 1 and "" or "s"), 2, "star")
end

local function SellNow()
	local n = 0
	for uid, pet in pairs(OwnedPets()) do
		if PetMatchesSell(pet.ItemData, uid) then
			SellPet(uid)
			n = n + 1
		end
	end
	Notify("Pets", ("Selling %d pet%s..."):format(n, n == 1 and "" or "s"), 2, "coins")
end

-- Native game endpoint: equips the best pets up to pen capacity. The game
-- enforces a 5s cooldown, so we only ask every 8s.
local function EquipBestTick()
	if not PetCfg.EquipBest then return end
	if os.clock() - EquipBestLast < 8 then return end
	EquipBestLast = os.clock()
	Invoke("Backpack: EquipBest")
end

-- ============================================================ ESP

local EspCfg = {
	Eggs = false,
	RareEggs = false,
	RareThreshold = 0,
	Guards = false,
}

local EspFolder
do
	EspFolder = Cleanup:Instance(Instance.new("Folder"))
	EspFolder.Name = "StealEggESP"
	EspFolder.Parent = Workspace
end

local EggMarkers = {} -- uid -> { part, billboard, label, sub }
local GuardMarkers = {} -- areaName -> marker

local function NewMarker(text, color)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = EspFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 9000
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard

	local sub = label:Clone()
	sub.Position = UDim2.new(0, 0, 0.5, 0)
	sub.Size = UDim2.new(1, 0, 0.5, 0)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(220, 220, 220)
	sub.Parent = billboard

	return part, billboard, label, sub
end

local function ClearMarkers(map)
	for _, m in pairs(map) do
		pcall(function() m.Part:Destroy() end)
	end
	table.clear(map)
end

local function EspTick()
	local hrp = MyHRP()
	local basePos = hrp and hrp.Position

	if EspCfg.Eggs or EspCfg.RareEggs then
		if EggStore:Refresh() then
			local wanted = {}
			for uid, rec in pairs(EggStore.ByUid) do
				local rar = EggRarityNum(rec.AssetCategory)
				local show = EspCfg.Eggs
					or (EspCfg.RareEggs and rar >= EspCfg.RareThreshold)
				if show and rec.BottomCFrame then
					wanted[uid] = true
					local marker = EggMarkers[uid]
					if not marker then
						local part, bb, label, sub = NewMarker(EggName(rec.AssetCategory), RarityColor(rar))
						marker = { Part = part, Billboard = bb, Label = label, Sub = sub }
						EggMarkers[uid] = marker
					end
					marker.Part.CFrame = rec.BottomCFrame + Vector3.new(0, 2, 0)
					local dist = basePos and (rec.BottomCFrame.Position - basePos).Magnitude or 0
					marker.Label.Text = ("%s [%s]"):format(EggName(rec.AssetCategory), EggRarityId(rec.AssetCategory))
					marker.Sub.Text = string.format("%.0f studs", dist)
					marker.Label.TextColor3 = RarityColor(rar)
				end
			end
			for uid in pairs(EggMarkers) do
				if not wanted[uid] then
					pcall(function() EggMarkers[uid].Part:Destroy() end)
					EggMarkers[uid] = nil
				end
			end
		end
	elseif next(EggMarkers) then
		ClearMarkers(EggMarkers)
	end

	if EspCfg.Guards then
		for _, g in ipairs(GuardModels()) do
			local root = g:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local area = g.Parent and g.Parent.Name or "?"
				local marker = GuardMarkers[area]
				if not marker then
					local part, bb, label, sub = NewMarker("Guard", DANGER)
					marker = { Part = part, Billboard = bb, Label = label, Sub = sub }
					GuardMarkers[area] = marker
				end
				marker.Part.CFrame = root.CFrame
				local state = g:GetAttribute("GuardState") or "Sleep"
				local dist = basePos and (root.Position - basePos).Magnitude or 0
				marker.Label.Text = ("Guard [%s]"):format(state)
				marker.Sub.Text = string.format("%s | %.0f studs", area, dist)
				marker.Label.TextColor3 = state == "Sleep" and Color3.fromRGB(150, 150, 150) or DANGER
			end
		end
	elseif next(GuardMarkers) then
		ClearMarkers(GuardMarkers)
	end
end

-- ============================================================ TASKS

Scheduler:Every("Mover", 0.04, MoverTick)
Scheduler:Every("EggStore", 2, function()
	EggStore:Refresh(true)
end)

Scheduler:Every("Farm", 0.15, FarmTick)
Scheduler:Every("AutoHatch", 2, AutoHatchTick)
Scheduler:Every("AutoPlace", 2, AutoPlaceTick)
Scheduler:Every("Treadmill", 0.8, TreadmillTick)
Scheduler:Every("Guards", 0.4, ScanGuards)
Scheduler:Every("BaseUpgrade", 1.2, BaseUpgradeTick)
Scheduler:Every("TreadmillUpgrade", 1.4, TreadmillUpgradeTick)
Scheduler:Every("OfflineClaim", 3, OfflineClaimTick)
Scheduler:Every("IndexClaim", 3, IndexClaimTick)
Scheduler:Every("Favorite", 2.5, FavoriteTick)
Scheduler:Every("Sell", 3, SellTick)
Scheduler:Every("EquipBest", 8, EquipBestTick)
Scheduler:Every("EggEsp", 1, EspTick)

Cleanup:Callback(function()
	ClearMarkers(EggMarkers)
	ClearMarkers(GuardMarkers)
	if IsCarrying() then DropHeldEgg("PlayerRequest") end
	if Treadmill.Active then Invoke(E.TreadmillUnequip) end
end)

-- ============================================================ HOME

do
	local Section = Tabs.Home:Section({ Title = HUB_NAME, Icon = "message-circle", Opened = true })

	Section:Paragraph({ Title = "loc:Discord", Desc = DISCORD })

	Section:Button({
		Title = "loc:Copy Discord Invite",
		Icon = "copy",
		Callback = function()
			setclipboard(DISCORD)
			Notify(HUB_NAME, "Invite copied to clipboard.", 2, "copy")
		end,
	})
end

-- ============================================================ FARM TAB

do
	local FarmSection = Tabs.Farm:Section({ Title = "loc:Steal", Opened = true })

	FarmSection:Toggle({
		Title = "loc:Auto Steal",
		Desc = "loc:Steal eggs from areas, run them home and place them.",
		Flag = "SAEAutoSteal",
		Value = false,
		Callback = function(v)
			FarmCfg.On = v
			if v then
				Island:Status("Farm")
			else
				FarmSetState("Idle")
				Farm.Target = nil
				Movement:Stop()
				Island:Clear()
			end
		end,
	})

	-- Area names discovered from the live GuardAreas folder.
	local function AreaNames()
		local names = {}
		local folder = Workspace:FindFirstChild("__OBJECTS")
			and Workspace.__OBJECTS:FindFirstChild("Areas")
			and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
		if folder then
			for _, area in ipairs(folder:GetChildren()) do
				if area:IsA("Model") then names[#names + 1] = area.Name end
			end
			table.sort(names)
		end
		return names
	end

	local AreaDropdown = FarmSection:Dropdown({
		Title = "loc:Target Areas",
		Desc = "loc:Empty = all areas",
		Values = AreaNames(),
		Value = nil,
		Multi = true,
		AllowNone = true,
		SearchBarEnabled = true,
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			local set = {}
			local list = AreaDropdown.Value
			if type(list) == "table" then
				for _, name in ipairs(list) do set[name] = true end
			elseif list then
				set[list] = true
			end
			FarmCfg.Areas = set
		end,
	})

	-- Egg categories from the asset directory.
	local function EggCategoryNames()
		local names = {}
		if AssetsDir then
			for cat in pairs(AssetsDir) do names[#names + 1] = cat end
			table.sort(names)
		end
		return names
	end

	local EggDropdown = FarmSection:Dropdown({
		Title = "loc:Target Eggs",
		Desc = "loc:Empty = all eggs",
		Values = EggCategoryNames(),
		Value = nil,
		Multi = true,
		AllowNone = true,
		SearchBarEnabled = true,
		Callback = function()
			local set = {}
			local list = EggDropdown.Value
			if type(list) == "table" then
				for _, name in ipairs(list) do set[name] = true end
			elseif list then
				set[list] = true
			end
			FarmCfg.Eggs = set
		end,
	})

	local rarityValues = { "Disabled" }
	for _, r in ipairs(RarityLadder) do rarityValues[#rarityValues + 1] = r.name end

	FarmSection:Dropdown({
		Title = "loc:Minimum Rarity",
		Values = rarityValues,
		Value = "Disabled",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			for _, r in ipairs(RarityLadder) do
				if r.name == v then FarmCfg.MinRarity = r.n return end
			end
			FarmCfg.MinRarity = 0
		end,
	})

	FarmSection:Dropdown({
		Title = "loc:Steal Priority",
		Values = { "Rarity", "Closest", "Income" },
		Value = "Rarity",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			FarmCfg.Priority = v
		end,
	})

	FarmSection:Dropdown({
		Title = "loc:Movement",
		Values = { "Hop", "Walk" },
		Value = "Hop",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			MoveCfg.Mode = v
			Movement.FallbackWalk = false
		end,
	})

	FarmSection:Slider({
		Title = "loc:Steal Hop Size",
		Flag = "SAEHopSize",
		Step = 5,
		Value = { Min = 10, Max = 120, Default = 30 },
		Callback = function(v) MoveCfg.HopSize = v end,
	})

	FarmSection:Slider({
		Title = "loc:Hop Speed",
		Desc = "loc:Hops per second. Higher is faster but easier for the game to correct.",
		Flag = "SAEHopRate",
		Step = 1,
		Value = { Min = 4, Max = 45, Default = 40 },
		Callback = function(v) MoveCfg.HopRate = v end,
	})

	local Place = Tabs.Farm:Section({ Title = "loc:Place Egg", Opened = true })

	Place:Toggle({
		Title = "loc:Auto Place Egg",
		Desc = "loc:Place carried eggs into your pen when you get home.",
		Flag = "SAEAutoPlace",
		Value = false,
		Callback = function(v) FarmCfg.AutoPlace = v end,
	})

	Place:Dropdown({
		Title = "loc:Place Rule",
		Values = { "Always", "When Pen Full" },
		Value = "Always",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			FarmCfg.PlaceRule = v == "When Pen Full" and "Full" or "Always"
		end,
	})

	Place:Toggle({
		Title = "loc:Auto Hatch Ready Eggs",
		Desc = "loc:Hatch growing eggs as soon as they're ready.",
		Flag = "SAEAutoHatch",
		Value = false,
		Callback = function(v) FarmCfg.AutoHatch = v end,
	})

	local TM = Tabs.Farm:Section({ Title = "loc:Treadmill", Opened = true })

	TM:Toggle({
		Title = "loc:Auto Treadmill",
		Desc = "loc:Train when idle. Pauses while carrying or stealing.",
		Flag = "SAEAutoTreadmill",
		Value = false,
		Callback = function(v)
			TreadmillCfg.On = v
			if not v then ExitTreadmill() end
		end,
	})

	local Safety = Tabs.Farm:Section({ Title = "loc:Guard Safety", Opened = true })

	Safety:Toggle({
		Title = "loc:Guard Warning",
		Desc = "loc:Notify when a guard is chasing you.",
		Flag = "SAEGuardWarning",
		Value = false,
		Callback = function(v) GuardCfg.Warning = v end,
	})

	Safety:Toggle({
		Title = "loc:Auto Drop Egg",
		Desc = "loc:Drop the carried egg the moment a guard chases you.",
		Flag = "SAEAutoDrop",
		Value = false,
		Callback = function(v) GuardCfg.AutoDrop = v end,
	})

	Safety:Slider({
		Title = "loc:Guard Chase Distance",
		Flag = "SAEChaseDist",
		Step = 1,
		Value = { Min = 10, Max = 60, Default = 25 },
		Callback = function(v) GuardCfg.Distance = v end,
	})
end

-- ============================================================ PROGRESS TAB

do
	local Auto = Tabs.Progress:Section({ Title = "loc:Auto Upgrades", Opened = true })

	Auto:Toggle({
		Title = "loc:Auto Upgrade Base",
		Desc = "loc:Buy the next base upgrade whenever affordable.",
		Flag = "SAEUpBase",
		Value = false,
		Callback = function(v) ProgressCfg.Base = v end,
	})

	Auto:Toggle({
		Title = "loc:Auto Upgrade Treadmill",
		Desc = "loc:Buy the next treadmill whenever affordable.",
		Flag = "SAEUpTM",
		Value = false,
		Callback = function(v) ProgressCfg.Treadmill = v end,
	})

	local Claim = Tabs.Progress:Section({ Title = "loc:Auto Claim", Opened = true })

	Claim:Toggle({
		Title = "loc:Auto Claim Offline Money",
		Flag = "SAEClaimOffline",
		Value = false,
		Callback = function(v) ProgressCfg.Offline = v end,
	})

	Claim:Toggle({
		Title = "loc:Auto Claim Index Rewards",
		Flag = "SAEClaimIndex",
		Value = false,
		Callback = function(v) ProgressCfg.Index = v end,
	})

	Tabs.Progress:Paragraph({
		Title = "loc:Costs",
		Desc = "loc:Base Lv2: 1K | Lv3: 1M | Lv4: 75M | Treadmill Lv2: 15K | Lv3: 250K | Lv4: 5M",
	})
end

-- ============================================================ ESP TAB

do
	local Egg = Tabs.ESP:Section({ Title = "loc:Eggs", Opened = true })

	Egg:Toggle({
		Title = "loc:ESP Eggs",
		Desc = "loc:Mark every area egg with name, rarity and distance.",
		Flag = "SAEEspEggs",
		Value = false,
		Callback = function(v) EspCfg.Eggs = v end,
	})

	Egg:Toggle({
		Title = "loc:ESP Rare Eggs",
		Desc = "loc:Only mark eggs at or above the threshold below.",
		Flag = "SAEEspRare",
		Value = false,
		Callback = function(v) EspCfg.RareEggs = v end,
	})

	local rarityValues = { "Common" }
	for _, r in ipairs(RarityLadder) do rarityValues[#rarityValues + 1] = r.name end

	Egg:Dropdown({
		Title = "loc:Rare Threshold",
		Values = rarityValues,
		Value = "Mythic",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			for _, r in ipairs(RarityLadder) do
				if r.name == v then EspCfg.RareThreshold = r.n return end
			end
		end,
	})

	local Guards = Tabs.ESP:Section({ Title = "loc:Guards", Opened = true })

	Guards:Toggle({
		Title = "loc:ESP Guards",
		Desc = "loc:Mark guards with state and distance.",
		Flag = "SAEEspGuards",
		Value = false,
		Callback = function(v) EspCfg.Guards = v end,
	})
end

-- ============================================================ PETS TAB

do
	local Fav = Tabs.Pets:Section({ Title = "loc:Auto Favorite", Opened = true })

	Fav:Toggle({
		Title = "loc:Auto Favorite",
		Flag = "SAEAutoFav",
		Value = false,
		Callback = function(v) PetCfg.AutoFavorite = v end,
	})

	local rarityValues = { "Disabled" }
	for _, r in ipairs(RarityLadder) do rarityValues[#rarityValues + 1] = r.name end

	Fav:Dropdown({
		Title = "loc:Favorite Min Rarity",
		Values = rarityValues,
		Value = "Disabled",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			for _, r in ipairs(RarityLadder) do
				if r.name == v then PetCfg.FavMinRarity = r.n return end
			end
			PetCfg.FavMinRarity = 0
		end,
	})

	Fav:Input({
		Title = "loc:Favorite Mutation",
		Placeholder = "Golden / Silver / empty = any",
		ClearTextOnFocus = false,
		Callback = function(v) PetCfg.FavMutation = v or "" end,
	})

	Fav:Button({
		Title = "loc:Favorite Pets Now",
		Icon = "star",
		Callback = FavoriteNow,
	})

	local Sell = Tabs.Pets:Section({ Title = "loc:Auto Sell", Opened = true })

	Sell:Toggle({
		Title = "loc:Auto Sell",
		Flag = "SAEAutoSell",
		Value = false,
		Callback = function(v) PetCfg.AutoSell = v end,
	})

	Sell:Dropdown({
		Title = "loc:Sell Rule",
		Values = { "Rarity Only", "Income Only", "Both" },
		Value = "Both",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			PetCfg.SellRule = v == "Rarity Only" and "Rarity"
				or (v == "Income Only" and "Income" or "Both")
		end,
	})

	local rarityValues = { "Disabled" }
	for _, r in ipairs(RarityLadder) do rarityValues[#rarityValues + 1] = r.name end

	Sell:Dropdown({
		Title = "loc:Pet Max Rarity",
		Desc = "loc:Sell pets at or below this rarity.",
		Values = rarityValues,
		Value = "Disabled",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			for _, r in ipairs(RarityLadder) do
				if r.name == v then PetCfg.MaxRarity = r.n return end
			end
			PetCfg.MaxRarity = 0
		end,
	})

	Sell:Input({
		Title = "loc:Pet Income Threshold",
		Desc = "loc:Sell pets below this income. 0 or empty = disabled. e.g. 10M",
		Placeholder = "10M",
		ClearTextOnFocus = false,
		Callback = function(v)
			local n = ParseMoney(v)
			if n ~= nil then PetCfg.IncomeThreshold = n end
		end,
	})

	Sell:Button({
		Title = "loc:Sell Pets Now",
		Icon = "coins",
		Callback = SellNow,
	})

	local Native = Tabs.Pets:Section({ Title = "loc:Game Auto Sell", Opened = true })

	local rarityIds = {}
	for _, r in ipairs(RarityLadder) do rarityIds[#rarityIds + 1] = r.name end

	local NativeDropdown = Native:Dropdown({
		Title = "loc:Auto Sell Rarities",
		Desc = "loc:The game's own auto sell. Runs server side, works offline.",
		Values = rarityIds,
		Value = nil,
		Multi = true,
		AllowNone = true,
		SearchBarEnabled = true,
		Callback = function()
			local set = {}
			local list = NativeDropdown.Value
			if type(list) == "table" then
				for _, name in ipairs(list) do set[name] = true end
			elseif list then
				set[list] = true
			end
			if PushNativeAutoSell(set) then
				local n = 0
				for _ in pairs(set) do n = n + 1 end
				Notify("Pets", n == 0 and "Game auto sell off."
					or ("Game auto sell: %d rarit%s."):format(n, n == 1 and "y" or "ies"), 2, "coins")
			end
		end,
	})

	-- Mirror whatever the game already has set so the dropdown is not lying.
	SafeCall(function()
		local state = Invoke(E.GetAutoSell)
		if type(state) ~= "table" then return end
		local sel = {}
		for id, on in pairs(state) do
			if on then sel[#sel + 1] = id end
		end
		if #sel > 0 then NativeDropdown:Select(sel) end
	end)

	local Equip = Tabs.Pets:Section({ Title = "loc:Auto Equip", Opened = true })

	Equip:Toggle({
		Title = "loc:Auto Equip Best",
		Desc = "loc:Equip the best pets into your pen (game's Equip Best).",
		Flag = "SAEEquipBest",
		Value = false,
		Callback = function(v) PetCfg.EquipBest = v end,
	})

	local Black = Tabs.Pets:Section({ Title = "loc:Sell Blacklist", Opened = true })

	local function PetOptionText(uid, pet)
		local muts = table.concat(pet.ItemData.Mutations or {}, "+")
		local mut = muts ~= "" and (" (" .. muts .. ")") or ""
		return ("%s [%s]%s uid:%s"):format(
			EggName(pet.ItemData.Category), EggRarityId(pet.ItemData.Category), mut, uid)
	end

	local PetDropdown = Black:Dropdown({
		Title = "loc:Add Pet To Blacklist",
		Desc = "loc:Select a pet, it will never be sold",
		Values = {},
		Value = nil,
		AllowNone = true,
		SearchBarEnabled = true,
	})

	Black:Button({
		Title = "loc:Blacklist Selected",
		Icon = "ban",
		Color = DANGER,
		Callback = function()
			local val = PetDropdown.Value
			if type(val) == "table" then val = val[1] end
			if not val then
				Notify("Pets", "Select a pet first.", 2, "triangle-alert")
				return
			end
			local uid = val:match("uid:(%S+)$")
			if uid then
				PetCfg.Blacklist[uid] = val:match("^(.-) uid:") or uid
				Notify("Pets", "Blacklisted.", 2, "ban")
			end
		end,
	})

	local BlackDropdown = Black:Dropdown({
		Title = "loc:Blacklisted Pets",
		Values = {},
		Value = nil,
		AllowNone = true,
		SearchBarEnabled = true,
	})

	local function RefreshBlacklist()
		local opts = {}
		for uid, name in pairs(PetCfg.Blacklist) do
			opts[#opts + 1] = (name or uid) .. " uid:" .. uid
		end
		table.sort(opts)
		SafeCall(function() BlackDropdown:Refresh(opts) end)
	end

	Black:Button({
		Title = "loc:Remove Selected",
		Icon = "minus",
		Callback = function()
			local val = BlackDropdown.Value
			if type(val) == "table" then val = val[1] end
			if not val then return end
			local uid = val:match("uid:(%S+)$")
			if uid then
				PetCfg.Blacklist[uid] = nil
				RefreshBlacklist()
			end
		end,
	})

	Black:Button({
		Title = "loc:Clear Blacklist",
		Icon = "eraser",
		Callback = function()
			table.clear(PetCfg.Blacklist)
			RefreshBlacklist()
			Notify("Pets", "Blacklist cleared.", 2, "eraser")
		end,
	})

	-- Keep the pet picker and the blacklist list fresh.
	Scheduler:Every("PetList", 3, function()
		local pets = OwnedPets()
		local opts = {}
		for uid, pet in pairs(pets) do
			if not PetCfg.Blacklist[uid] then
				opts[#opts + 1] = PetOptionText(uid, pet)
			end
		end
		table.sort(opts)
		SafeCall(function() PetDropdown:Refresh(opts) end)
		RefreshBlacklist()
	end)

	Tabs.Pets:Paragraph({
		Title = "loc:Note",
		Desc = "Blacklisted pets are never sold; favorited pets are protected too. Use Game Auto Sell for plain rarity rules, and the script's own Auto Sell when you need income or blacklist filtering.",
	})
end

-- ============================================================ WEBHOOK TAB

do
	local Hook = Tabs.Webhook:Section({ Title = "loc:Discord", Opened = true })

	if not httprequest then
		Hook:Paragraph({
			Title = "loc:Unavailable",
			Desc = "loc:Your executor exposes no HTTP request function, so webhooks are disabled.",
		})
	else
		Hook:Input({
			Title = "loc:Discord Webhook URL",
			Desc = "loc:Paste your Discord webhook URL here",
			Placeholder = "https://discord.com/api/webhooks/...",
			Flag = "SAEWebhookUrl",
			ClearTextOnFocus = false,
			Callback = function(v)
				v = tostring(v or ""):gsub("%s+", "")
				if v ~= "" and not v:match(WEBHOOK_PATTERN) then
					Notify("Webhook", "That does not look like a Discord webhook URL.", 4, "triangle-alert")
					WebhookCfg.Url = ""
					return
				end
				WebhookCfg.Url = v
				if v ~= "" then Notify("Webhook", "URL saved.", 2, "check") end
			end,
		})

		Hook:Toggle({
			Title = "loc:Webhook Egg Steal",
			Desc = "loc:Send a Discord notification when an egg is stolen",
			Flag = "SAEWebhookSteal",
			Value = false,
			Callback = function(v)
				WebhookCfg.OnSteal = v
				if v and WebhookCfg.Url == "" then
					Notify("Webhook", "Set a webhook URL first.", 3, "triangle-alert")
				end
			end,
		})

		local hookRarity = { "All" }
		for _, r in ipairs(RarityLadder) do hookRarity[#hookRarity + 1] = r.name end

		Hook:Dropdown({
			Title = "loc:Webhook Min Rarity",
			Desc = "loc:Only send for eggs at or above this rarity",
			Values = hookRarity,
			Value = "All",
			Callback = function(v)
				if type(v) == "table" then v = v[1] end
				for _, r in ipairs(RarityLadder) do
					if r.name == v then WebhookCfg.MinRarity = r.n return end
				end
				WebhookCfg.MinRarity = 0
			end,
		})

		Hook:Button({
			Title = "loc:Test Webhook",
			Desc = "loc:Send a test notification to verify the URL",
			Icon = "send",
			Callback = function()
				if not WebhookReady() then
					Notify("Webhook", "Set a valid webhook URL first.", 3, "triangle-alert")
					return
				end
				SendWebhook({
					title = "Webhook Connected",
					description = "Supra | " .. HUB_NAME .. " is linked to this channel.",
					color = 5017343,
					footer = { text = LocalPlayer.Name .. " | " .. os.date("%X") },
				})
				Notify("Webhook", "Test sent. Check your channel.", 3, "send")
			end,
		})
	end

end

-- ============================================================ SETTINGS

do
	local ConfigManager = Window.ConfigManager
	local ConfigSection = Tabs.Settings:Section({ Title = "loc:Configs", Opened = true })

	if ConfigManager then
		local NameBox = ConfigSection:Input({
			Title = "loc:Name",
			Placeholder = "my config",
			ClearTextOnFocus = false,
		})

		local List = ConfigSection:Dropdown({
			Title = "loc:Saved",
			Values = ConfigManager:AllConfigs() or {},
			Value = nil,
			AllowNone = true,
		})

		ConfigSection:Button({
			Title = "loc:Save",
			Icon = "save",
			Callback = function()
				local name = NameBox.Value
				if not name or name == "" then
					Notify("Configs", "Name it first.", 3, "triangle-alert")
					return
				end
				Window.CurrentConfig = ConfigManager:CreateConfig(name)
				if Window.CurrentConfig then
					Window.CurrentConfig:Save()
					SafeCall(function() List:Refresh(ConfigManager:AllConfigs()) end)
					Notify("Configs", "Saved '" .. name .. "'.", 2, "check")
				end
			end,
		})

		ConfigSection:Button({
			Title = "loc:Load",
			Icon = "folder-open",
			Callback = function()
				local name = List.Value
				if typeof(name) == "table" then name = name[1] end
				if not name then return end
				Window.CurrentConfig = ConfigManager:Config(name)
				if Window.CurrentConfig then
					Window.CurrentConfig:Load()
					Notify("Configs", "Loaded '" .. name .. "'.", 2, "refresh-cw")
				end
			end,
		})
	else
		ConfigSection:Paragraph({
			Title = "loc:Unavailable",
			Desc = "loc:Your executor has no file access, so configs are disabled.",
		})
	end

	local UI = Tabs.Settings:Section({ Title = "loc:Interface", Opened = true })

	UI:Keybind({
		Title = "loc:Menu Key",
		Flag = "MenuKey",
		Value = "RightShift",
		Callback = function(key)
			local code = Enum.KeyCode[key]
			if code then Window:SetToggleKey(code) end
		end,
	})

	-- Themes ship with the library, so read the list rather than hardcoding it
	-- and going stale the next time the UI is updated.
	local themeNames = {}
	SafeCall(function()
		for _, name in ipairs(WindUI:GetThemes() or {}) do
			themeNames[#themeNames + 1] = name
		end
		table.sort(themeNames)
	end)

	if #themeNames > 0 then
		UI:Dropdown({
			Title = "loc:Theme",
			Desc = "loc:Colour scheme for the whole menu",
			Values = themeNames,
			Value = WindUI:GetCurrentTheme() or "Dark",
			Flag = "SAETheme",
			SearchBarEnabled = true,
			Callback = function(v)
				if type(v) == "table" then v = v[1] end
				if v then SafeCall(function() WindUI:SetTheme(v) end) end
			end,
		})
	end

	local langNames = {}
	for _, l in ipairs(LANGUAGES) do langNames[#langNames + 1] = l.Name end

	UI:Dropdown({
		Title = "loc:Language",
		Desc = "loc:Menu language",
		Values = langNames,
		Value = "English",
		Flag = "SAELanguage",
		Callback = function(v)
			if type(v) == "table" then v = v[1] end
			for _, l in ipairs(LANGUAGES) do
				if l.Name == v then
					SafeCall(function() WindUI:SetLanguage(l.Code) end)
					return
				end
			end
		end,
	})

	UI:Slider({
		Title = "loc:UI Scale",
		Step = 0.05,
		Value = { Min = 0.5, Max = 1.5, Default = 1 },
		Callback = function(v) Window:SetUIScale(v) end,
	})

	UI:Toggle({
		Title = "loc:Show Island",
		Desc = "loc:The status pill at the top of the screen",
		Value = true,
		Callback = function(v) Island:Visible(v) end,
	})

	local Danger = Tabs.Settings:Section({ Title = "loc:Unload", Opened = true })

	Danger:Button({
		Title = "Unload " .. HUB_NAME,
		Desc = "loc:Restores everything this script changed and closes the menu",
		Icon = "power",
		Color = DANGER,
		Callback = function()
			Cleanup:Destroy()
			pcall(function() Window:Destroy() end)
		end,
	})
end

-- ============================================================ BOOT

Window:SelectTab(1)
Notify(HUB_NAME, "Loaded. Press RightShift to toggle.", 4, "check")