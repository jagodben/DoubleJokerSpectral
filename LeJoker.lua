--- STEAMODDED HEADER
--- MOD_NAME: LeJoker
--- MOD_ID: LeJoker
--- MOD_AUTHOR: [YourNameHere]
--- MOD_DESCRIPTION: A Joker that starts at X1 Mult and adds X0.23 Mult for each King of Spades or Clubs played.

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

-- Function to refresh sorting and localization (still useful if other items are added)
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
    -- Define localization directly for SMODS.Joker:new
    local lejoker_localization = {
        name = "LeJoker",
        text = {
            "Each played Black King adds {X:mult,C:white}#1#X {} Mult",
            "Currently {X:mult,C:white}X#2# {} Mult"
        }
    }

    -- Create the Joker using SMODS.Joker:new
    local lejoker = SMODS.Joker:new(
        "LeJoker", -- Name
        "j_lejoker", -- Key (ID)
        { -- Ability Data (this becomes self.ability)
            set = "Joker", -- Important for 'set' property
            extra = { -- Our custom data, directly under ability data
                current_Xmult = 1, -- Initial multiplier
                Xmult_mod = 0.23, -- Amount to add each time
            }
        },
        {x = 0, y = 0}, -- Sprite Position (for the card's visual center)
        lejoker_localization, -- Localization data
        1, -- Rarity (explicitly passed to SMODS.Joker:new)
        4  -- Cost (explicitly passed to SMODS.Joker:new)
    )

    lejoker:register()

    -- Register the sprite. The atlas will be 'j_lejoker' based on the key.
    SMODS.Sprite:new("j_lejoker", SMODS.findModByID(MOD_ID).path, "j_lejoker.png", 71, 95, "asset_atli"):register()

    -- The refresh_items() call after adding the Joker is now less critical
    -- as SMODS.Joker:new handles registration, but keeping it won't hurt.
    refresh_items()

    -- Override the UI generation for LeJoker to display dynamic multiplier
    local generate_UIBox_ability_tableref = Card.generate_UIBox_ability_table
    function Card:generate_UIBox_ability_table()
        if self.ability.set == 'Joker' and self.ability.name == 'LeJoker' then
            -- Defensive check: Ensure self.ability.extra is a table and has the necessary fields
            if type(self.ability.extra) ~= "table" or 
               self.ability.extra.current_Xmult == nil or self.ability.extra.Xmult_mod == nil then
                sendDebugMessage("LeJoker: Initializing/Re-initializing self.ability.extra in UI due to unexpected state.")
                self.ability.extra = {
                    current_Xmult = 1,
                    Xmult_mod = 0.23,
                }
            end

            -- Access 'extra' via self.ability.extra
            local loc_vars = {
                self.ability.extra.Xmult_mod,
                self.ability.extra.current_Xmult
            }

            local badges = {}
            local card_type = self.ability.set or "None"

            if (card_type ~= 'Locked' and card_type ~= 'Undiscovered' and card_type ~= 'Default') or self.debuff then
                badges.card_type = card_type
            end
            if self.ability.set == 'Joker' and self.bypass_discovery_ui then
                badges.force_rarity = true
            end
            if self.edition then
                if self.edition.type == 'negative' and self.edition.consumeable then
                    badges[#badges + 1] = 'negative_consumable'
                else
                    badges[#badges + 1] = (self.edition.type == 'holo' and 'holographic' or self.edition.type)
                end
            end
            if self.seal then badges[#badges + 1] = string.lower(self.seal) .. '_seal' end
            if self.ability.eternal then badges[#badges + 1] = 'eternal' end
            if self.pinned then badges[#badges + 1] = 'pinned_left' end

            if self.sticker then
                loc_vars.sticker = self.sticker
            end

            -- generate_card_ui expects self.config.center for visual data.
            return generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, nil, nil, nil)
        else
            -- If it's not LeJoker, call the original function to handle its UI
            return generate_UIBox_ability_tableref(self)
        end
    end

    -- Define the Joker's primary calculate function for its Xmult contribution
    SMODS.Jokers.j_lejoker.calculate = function(self, context)
        sendDebugMessage("LeJoker: SMODS.Jokers.j_lejoker.calculate called. Current Xmult: " .. tostring(self.ability.extra.current_Xmult))
        
        -- Crucial: Only apply the multiplier at the very end of the calculation context
        -- This prevents premature arithmetic on uninitialized global scoring variables.
        if SMODS.end_calculate_context(context) then
            sendDebugMessage("LeJoker: SMODS.Jokers.j_lejoker.calculate applying Xmult.")
            return {
                Xmult = self.ability.extra.current_Xmult, 
                card = self
            }
        end
        -- If not end_calculate_context, return nothing to avoid interfering with other calculations
        return nil
    end
end

-- Joker effect: This override is now ONLY for INCREMENTING the multiplier
-- when a Black King is played. It does NOT return the Xmult for the hand.
local calculate_jokerref = Card.calculate_joker
function Card:calculate_joker(context)
    -- Call original for other effects before our logic
    local ret_val = calculate_jokerref(self, context) 

    -- Only process for LeJoker and if not debuffed
    if self.ability.set == "Joker" and self.ability.name == "LeJoker" and not self.debuff then
        sendDebugMessage("LeJoker: Entering Card:calculate_joker. Context repetition: " .. tostring(context.repetition))

        -- Defensive check: Ensure self.ability.extra is a table and has the necessary fields
        if type(self.ability.extra) ~= "table" or 
           self.ability.extra.current_Xmult == nil or self.ability.extra.Xmult_mod == nil then
            sendDebugMessage("LeJoker: Initializing/Re-initializing self.ability.extra in Card:calculate_joker due to unexpected state.")
            self.ability.extra = {
                current_Xmult = 1,
                Xmult_mod = 0.23,
            }
        end

        -- Logic for INCREMENTING the multiplier (only on King play and not repetition)
        -- This part only modifies the Joker's internal state.
        if context and context.cardarea == G.play and not context.repetition then
            sendDebugMessage("LeJoker: Condition met for potentially incrementing multiplier (non-repetition).")
            local card = context.other_card or context.card or nil

            if type(card) == "table" and card.get_id and card.base and card.base.suit then
                local is_king = card:get_id() == 13
                local is_clubs_or_spades = card.base.suit == "Clubs" or card.base.suit == "Spades"

                sendDebugMessage("LeJoker: Card being scored - ID: " .. tostring(card:get_id()) .. ", Suit: " .. tostring(card.base.suit))

                if is_king and is_clubs_or_spades then
                    sendDebugMessage("LeJoker: Black King detected! Incrementing Xmult.")
                    self.ability.extra.current_Xmult = self.ability.extra.current_Xmult + self.ability.extra.Xmult_mod
                    -- Return a message here if we want a visual pop-up when the multiplier increases
                    return { message = localize('k_upgrade_ex'), card = self }
                end
            end
        end
    end

    -- Always return the original ret_val from the base function for other effects
    -- This Joker's Xmult contribution is handled by SMODS.Jokers.j_lejoker.calculate
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

----------------------------------------------
------------MOD CODE END----------------------
