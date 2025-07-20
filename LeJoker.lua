--- STEAMODDED HEADER
--- MOD_NAME: LeJoker
--- MOD_ID: LeJoker
--- MOD_AUTHOR: [YourNameHere]
--- MOD_DESCRIPTION: A Joker that gives ×4 Mult to Kings of Spades or Clubs.

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = "LeJoker"

-- Extend Card:set_sprites to handle custom atlases
local set_spritesref = Card.set_sprites
function Card:set_sprites(_center, _front)
    set_spritesref(self, _center, _front)
    if _center then
        if _center.set then
            if (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.atlas then
                self.children.center.atlas = G.ASSET_ATLAS
                    [(_center.atlas or (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.set) or 'centers']
                self.children.center:set_sprite_pos(_center.pos)
            end
        end
    end
end

-- Function to add new item (Joker) with sprite and localization
function add_item(mod_id, pool, id, data, desc)
    data.pos = { x = 0, y = 0 }
    data.key = id
    data.atlas = mod_id .. id
    SMODS.Sprite:new(mod_id .. id, SMODS.findModByID(mod_id).path, id .. ".png", 71, 95, "asset_atli"):register()

    data.key = id
    data.order = #G.P_CENTER_POOLS[pool] + 1
    G.P_CENTERS[id] = data
    table.insert(G.P_CENTER_POOLS[pool], data)

    if pool == "Joker" then
        table.insert(G.P_JOKER_RARITY_POOLS[data.rarity], data)
    end

    G.localization.descriptions[pool][id] = desc
end

-- Function to refresh sorting and localization
function refresh_items()
    for k, v in pairs(G.P_CENTER_POOLS) do
        table.sort(v, function(a, b) return a.order < b.order end)
    end

    for g_k, group in pairs(G.localization) do
        if g_k == 'descriptions' then
            for _, set in pairs(group) do
                for _, center in pairs(set) do
                    center.text_parsed = {}
                    for _, line in ipairs(center.text) do
                        center.text_parsed[#center.text_parsed + 1] = loc_parse_string(line)
                    end
                    center.name_parsed = {}
                    for _, line in ipairs(type(center.name) == 'table' and center.name or { center.name }) do
                        center.name_parsed[#center.name_parsed + 1] = loc_parse_string(line)
                    end
                    if center.unlock then
                        center.unlock_parsed = {}
                        for _, line in ipairs(center.unlock) do
                            center.unlock_parsed[#center.unlock_parsed + 1] = loc_parse_string(line)
                        end
                    end
                end
            end
        end
    end

    for k, v in pairs(G.P_JOKER_RARITY_POOLS) do
        table.sort(G.P_JOKER_RARITY_POOLS[k], function(a, b) return a.order < b.order end)
    end
end

-- Joker initialization
function SMODS.INIT.LeJoker()
    add_item(MOD_ID, "Joker", "j_lejoker", {
        unlocked = true,
        discovered = true,
        rarity = 1,
        cost = 4,
        name = "LeJoker",
        set = "Joker",
        config = {
            extra = 4,
        }
    }, {
        name = "LeJoker",
        text = {
            "Each played Black King gives {X:mult,C:white}X4 {} Mult"
        }
    })

    refresh_items()
end

-- Joker effect: ×4 multiplier for King of Spades or Clubs
local calculate_jokerref = Card.calculate_joker
function Card:calculate_joker(context)
    local ret_val = calculate_jokerref(self, context)

    -- Only apply for LeJoker and not debuffed
    if self.ability.set == "Joker" and self.ability.name == "LeJoker" and not self.debuff then
        -- Only act during scoring phase
        if context and context.cardarea == G.play then
            -- Determine which card is being scored
            local card = context.other_card or context.card or nil

            -- Make sure it's a valid card object
            if type(card) == "table" and card.get_id and card.base and card.base.suit then
                local is_king = card:get_id() == 13
                local is_clubs_or_spades = card.base.suit == "Clubs" or card.base.suit == "Spades"

                if is_king and is_clubs_or_spades then
                    return {
                        Xmult_mod = 4,
                        card = self
                    }
                end
            end
        end
    end

    return ret_val
end


-- Track LeJoker ownership in save
local add_to_deck_ref = Card.add_to_deck
function Card:add_to_deck()
    if G.GAME and self.ability.set == "Joker" then
        if G.GAME[MOD_ID .. "unique_jokers_owned"] == nil then
            G.GAME[MOD_ID .. "unique_jokers_owned"] = {}
        end
        G.GAME[MOD_ID .. "unique_jokers_owned"][self.ability.name] = true
    end
    return add_to_deck_ref(self)
end

-- Extend UI badges logic
local card_uiref = Card.generate_UIBox_ability_table
function Card:generate_UIBox_ability_table()
    local badges = {}
    local card_type = self.ability.set or "None"
    local loc_vars = nil

    if (card_type ~= 'Locked' and card_type ~= 'Undiscovered' and card_type ~= 'Default') or self.debuff then
        badges.card_type = card_type
    end
    if self.ability.set == 'Joker' and self.bypass_discovery_ui then
        badges.force_rarity = true
    end
    if self.edition then
        if self.edition.type == 'negative' and self.ability.consumeable then
            badges[#badges + 1] = 'negative_consumable'
        else
            badges[#badges + 1] = (self.edition.type == 'holo' and 'holographic' or self.edition.type)
        end
    end
    if self.seal then badges[#badges + 1] = string.lower(self.seal) .. '_seal' end
    if self.ability.eternal then badges[#badges + 1] = 'eternal' end
    if self.pinned then badges[#badges + 1] = 'pinned_left' end

    if self.sticker then
        loc_vars = loc_vars or {}; loc_vars.sticker = self.sticker
    end

    return card_uiref(self)
end

----------------------------------------------
------------MOD CODE END----------------------
