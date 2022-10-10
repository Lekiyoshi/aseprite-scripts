----------------------------------------------------------------------
-- Reduces the bit-depth of the palette colors.
----------------------------------------------------------------------
-- Author:  Sandor Drieënhuizen
-- Source:  https://github.com/sandord/aseprite-scripts
-- License: MIT
----------------------------------------------------------------------

local spr = app.activeSprite

if not spr then
  return app.alert("There is no active sprite")
end

local dlg = Dialog("Reduce palette bit-depth")

local function showHelp()
  app.alert{title="Help", text={
    "This extension reduces the bit-depth of each palette color, which could be desirable if you",
    "want to match the color limitations of retro hardware such as an Atari ST.",
    "It doesn't reduce the number of palette entries, it simply alters existing palette entries.",
    "",
    "The Atari ST has 3 bits per primary color (512 possible colors, #000-#777).",
    "The Atari STE and the Commodore Amiga have 4 bits (4096 possible colors, #000-#fff).",
    "",
    "The option to fix the dynamic range ensures that the brightest white becomes #ffffff,",
    "while retaining pure blacks. This doesn't matter when processing the sprite for use on",
    "reduced bit-depth hardware (assuming that the lower bits are ignored) but corrects the reduced",
    "brightness while designing in Aseprite and/or viewing the sprite on a modern device."}}
end

local function round(num)
  -- Rounds to the nearest integer.
  if num >= 0 then
    return math.floor(num+.5) 
  else
    return math.ceil(num-.5)
  end
end

local function roundChannel(channel, bits)
  -- Rounds color channel values to nearest multiple, determined by bit depth.
  mult = 0xff/(0xff >> (8 - bits))
  return round(channel/mult) << (8 - bits)
end

local function alterPalette()
  dlg:close()
  
  app.transaction(
    function()
      local pal = spr.palettes[1]
      local mask = (0xff << (8 - dlg.data.bits)) & 0xff

      -- The multiplier will optionally fix the dynamic range.
      local mply

      if dlg.data.fixDR then
        mply = 0xff / mask
      else
        mply = 1
      end

      if dlg.data.roundValues then
        for i = 0,#pal-1 do
          local color = pal:getColor(i)

          color.red = roundChannel(color.red, dlg.data.bits) * mply
          color.green = roundChannel(color.green, dlg.data.bits) * mply
          color.blue = roundChannel(color.blue, dlg.data.bits) * mply

          pal:setColor(i, color)
        end
      else
        for i = 0,#pal-1 do
          local color = pal:getColor(i)

          color.red = (color.red & mask) * mply
          color.green = (color.green & mask) * mply
          color.blue = (color.blue & mask) * mply

          pal:setColor(i, color)
        end
      end
    end
  )

    app.refresh()
end

local function selectBits(value)
  dlg:modify{id="bits", value=value}
  dlg:modify{id="bits", enabled=false}
end

local function selectPreset()
  if dlg.data.preset == "Custom" then
    dlg:modify{id="bits", enabled=true}
  elseif dlg.data.preset == "Atari ST" then
    selectBits(3)
  elseif dlg.data.preset == "Atari STE" then
    selectBits(4)
  elseif dlg.data.preset == "Commodore Amiga" then
    selectBits(4)
  end
end

dlg
  :separator{ text="Options" }
  :combobox{ label="Preset:", id="preset", option="Atari ST", options={"Atari ST", "Atari STE", "Commodore Amiga", "Custom"}, onchange=function() selectPreset() end }
  :newrow()
  :slider{ label="Bits:", id="bits", min=1, max=7, value=3, enabled=false}
  :check{ label="Fix dynamic range:", id="fixDR", selected=true }
  :check{ label="Round values:", id="roundValues", selected=false }

dlg:button{ text="&Help",onclick=function() showHelp() end }
dlg:button{ text="&OK", focus=true, onclick=function() alterPalette() end }
dlg:button{ text="&Cancel",onclick=function() dlg:close() end }

dlg:show{ wait=false }
