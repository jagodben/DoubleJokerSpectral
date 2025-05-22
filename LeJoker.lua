--- STEAMODDED HEADER
--- MOD_NAME: LeJoker
--- MOD_ID: LeJoker
--- MOD_AUTHOR: [jagodben]
--- MOD_DESCRIPTION: A joker based on LeBron James

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.INIT.LeJoker()

    -- Localization
    SMODS.insert_localization({
    j_lejoker = {
        name = "LeJoker",
        text = {
            "Gains {C:mult}+#1#{} Mult for every",
            "{C:attention}King{} scored this round",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive})"
        }
    }
})

    SMODS.Sprite:new(
        "j_lejoker",
        SMODS.findModByID("LeJoker").path,
        "assets/lejoker.png",
        71,
        95,
        "asset_atli"
    ):register()

    -- Joker definition
    local lejoker = SMODS.Joker:new(
        "LeJoker",           -- Display name
        "lejoker",           -- Key
        { extra = { per_king = 0.1, total_mult = 0 } },
        { x = 0, y = 0 },
        localization["j_lejoker"],
        2,                   -- Rarity
        5                    -- Cost
    )

    -- Optional config flags
    lejoker.config.consumeable = false
    lejoker:set_eternal(false)
    lejoker:set_spectral(false)

    -- Dynamic vars shown in tooltip
    function lejoker.loc_vars(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.per_king,
                card.ability.extra.total_mult or 0
            }
        }
    end

    -- Gameplay effect
    function lejoker.calculate(self, card, context)
        if context.joker_main then
            local king_count = 0
            if context.full_hand then
                for _, v in ipairs(context.full_hand) do
                    if v.base and v.base.id == 'K' then
                        king_count = king_count + 1
                    end
                end
            end

            local bonus = king_count * card.ability.extra.per_king
            card.ability.extra.total_mult = bonus

            return {
                mult_mod = bonus,
                message = localize { type = 'variable', key = 'a_mult', vars = { bonus } }
            }
        end
    end

    lejoker:register()
end

----------------------------------------------
------------MOD CODE END----------------------