local _, core = ...;
core.loaded = false
core.itemWaitTable = {}
core.bankIsOpen = false
core.merchantIsOpen = false

local lastTimeRestocked = GetTime()


local function count(T)
  local i = 0
  for _, _ in pairs(T) do
    i = i+1
  end
  return i
end


local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("MERCHANT_SHOW");
events:RegisterEvent("MERCHANT_CLOSED");
events:RegisterEvent("BANKFRAME_OPENED");
events:RegisterEvent("BANKFRAME_CLOSED");
events:RegisterEvent("GET_ITEM_INFO_RECEIVED");
events:RegisterEvent("PLAYER_LOGOUT");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("UI_ERROR_MESSAGE");
events:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function events:ADDON_LOADED(name)
  if name ~= "Restocker" then return end


  -- NEW RESTOCKER
  if not Restocker then
    Restocker = {}
    Restocker.autoBuy = true
    Restocker.restockFromBank = true
    Restocker.profiles = {}
    Restocker.profiles.default = {}
    Restocker.currentProfile = "default"
    Restocker.framePos = {}
    Restocker.autoOpenAtBank = false
    Restocker.autoOpenAtMerchant = false
    Restocker.restockFromBank = true
  end

  for profile, _ in pairs(Restocker.profiles) do
    for _, item in ipairs(Restocker.profiles[profile]) do
      item.itemID = tonumber(item.itemID)
    end
  end

  local f=InterfaceOptionsFrame;
  f:SetMovable(true);
  f:EnableMouse(true);
  f:SetUserPlaced(true);
  f:SetScript("OnMouseDown", f.StartMoving);
  f:SetScript("OnMouseUp", f.StopMovingOrSizing);


  SLASH_RESTOCKER1= "/restocker";
  SLASH_RESTOCKER2= "/rs";
  SlashCmdList.RESTOCKER = function(msg)
    core:SlashCommand(msg)
  end

  core:CreateOptionsMenu()
  core:Show()
  core:Hide()
  core.loaded = true
end

function events:PLAYER_ENTERING_WORLD(login, reloadui)
  if not core.loaded then return end
  if login or reloadui then
    core:Print("|cffff2200Restocker|r loaded. /rs or /restocker to open addon.")
  end
end

function events:MERCHANT_SHOW()
  core.buying = true
  if not Restocker.autoBuy then return end -- If not autobuying then return
  if IsShiftKeyDown() then return end -- If shiftkey is down return
  core.merchantIsOpen = true
  if count(Restocker.profiles[Restocker.currentProfile]) == 0 then return end -- If profile is emtpy then return
  if GetTime() - lastTimeRestocked < 1 then return end -- If vendor repoened within 1 second then return (only activate addon once per second)

  lastTimeRestocked = GetTime()
  local boughtSomething = false
  if Restocker.autoOpenAtMerchant then core:Show() end

  local _, class = UnitClass("PLAYER")
  local poisonReagentsNeeded = class == "ROGUE" and core:getPoisonReagents() or {}
  local buyTable = {}

  local restockList = Restocker.profiles[Restocker.currentProfile]

  -- BUILD THE TABLE USED FOR BUYING ITEMS
  for _, item in ipairs(restockList) do
    local numInBags = GetItemCount(item.itemName, false)
    local numNeeded = item.amount - numInBags
    if numNeeded > 0 then
      if not buyTable[item.itemName] then
        buyTable[item.itemName] = {}
        buyTable[item.itemName]["numNeeded"] = numNeeded
        buyTable[item.itemName]["itemName"] = item.itemName
        buyTable[item.itemName]["itemID"] = item.itemID
        buyTable[item.itemName]["itemLink"] = item.itemLink
      else
        buyTable[item.itemName]["numNeeded"] = buyTable[item.itemName]["numNeeded"] + numNeeded
      end
    end
  end

  -- INSERT POISON REAGENTS INTO BUYTABLE
  for reagent, amount in pairs(poisonReagentsNeeded) do
    if not buyTable[reagent] then
      buyTable[reagent] = {}
      buyTable[reagent]["numNeeded"] = amount
      buyTable[reagent]["itemName"] = reagent
    else
      buyTable[reagent]["numNeeded"] = buyTable[reagent]["numNeeded"] + amount
    end
  end


  -- LOOP THROUGH VENDOR ITEMS
  for i = 0, GetMerchantNumItems() do
    if not core.buying then return end
    local itemName, _, _, _, numAvailable = GetMerchantItemInfo(i)
    local itemLink = GetMerchantItemLink(i)


    if buyTable[itemName] then
      local item = buyTable[itemName]
      local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemLink)


      if item.numNeeded > numAvailable and numAvailable > 0 then
        BuyMerchantItem(i, numAvailable)
        boughtSomething = true
      else
        for n = item.numNeeded, 1, -itemStackCount do
          if n > itemStackCount then
            BuyMerchantItem(i, itemStackCount)
            boughtSomething = true
          else
            BuyMerchantItem(i, n)
            boughtSomething = true
          end
        end -- forloop
      end
    end -- if buyTable[itemName] ~= nil
  end -- for loop GetMerchantNumItems()


  if boughtSomething then core:Print(core.defaults.prefix .. "finished restocking from vendor.") end

end


function events:MERCHANT_CLOSED(event, ...)
  core.merchantIsOpen = false
  core:Hide()
end







function events:BANKFRAME_OPENED(event, ...)
  if IsShiftKeyDown() then return end
  if not Restocker.restockFromBank then return end
  if Restocker.profiles[Restocker.currentProfile] == nil then return end

  if Restocker.autoOpenAtBank then core:Show() end

  core.bankIsOpen = true
  core.currentlyRestocking = true
end

function core:triggerBankOpen()
  events:BANKFRAME_OPENED()
end


function events:BANKFRAME_CLOSED(event, ...)
  core.bankIsOpen = false
  core.currentlyRestocking = false
  core:Hide()
end




function events:GET_ITEM_INFO_RECEIVED(itemID, success)
  if success == nil then return end
  if core.itemWaitTable[itemID] then
    core.itemWaitTable[itemID] = nil
    core:addItem(itemID)
  end
end



function events:PLAYER_LOGOUT()
  if Restocker.framePos == nil then Restocker.framePos = {} end

  core:Show()
  core:Hide()

  local point, relativeTo, relativePoint, xOfs, yOfs = core.addon:GetPoint(core.addon:GetNumPoints())

  Restocker.framePos.point = point
  Restocker.framePos.relativePoint = relativePoint
  Restocker.framePos.xOfs = xOfs
  Restocker.framePos.yOfs = yOfs
end


function events:UI_ERROR_MESSAGE(id, messsage)
  if id == 2 or id == 3 then -- catch inventory / bank full error messages
    core.currentlyRestocking = false
    core.buying = false
  end
end
